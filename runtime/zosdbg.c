/* zosdbg.c: Debug-Agent für den z/OS-Debugger (VS-Code-Erweiterung "z/OS Pascal").
 *
 * Programme, die mit ZOS_ZDBG=1 übersetzt sind (scripts/zdbg-instrument.py), rufen
 *   FPC_ZOS_DBG_ENTER(satz)       am Anfang jeder Routine (Frame-Satz im Stack)
 *   FPC_ZOS_DBG_LINE(satz, zeile) vor jeder neuen Quellzeile
 * Ohne die Umgebungsvariable ZDBG=1 kehren beide sofort zurück.
 *
 * Mit ZDBG=1 übernimmt der Agent stdin/stdout der ssh-Sitzung: die Programmausgabe (fd 1, 2)
 * läuft über eine Pipe und geht als "@@Z O <json>" hinaus, die Standardeingabe des Programms
 * kommt aus einer Pipe (Befehl IN); Befehle kommen zeilenweise über stdin. sshd wandelt zwischen ASCII und
 * EBCDIC (IBM-1047); der Agent schreibt deshalb EBCDIC und liest EBCDIC.
 *
 * Befehle (Adapter -> Agent)          Antworten/Ereignisse (Agent -> Adapter)
 *   B <datei> <zeile> ...               @@Z READY                 Agent bereit (vor Zeile 1)
 *   RUN | RUNSTOP                       @@Z STOP <grund> <zeile> <thread> <datei>
 *   C  N  I  O  P                       @@Z R <id> <json>         Antwort
 *   H <id>                (Threads)     @@Z O <json-string>       Programmausgabe
 *   T <id> <thread>                     @@Z END                   Programmende
 *   L <id> <thread> <frame>
 *   G <id> <thread> <frame>
 *   V <id> <typ-hex>:<adresse-hex>
 *   IN <json-string>   Standardeingabe;  EOF  Standardeingabe schließen
 *   X  (Programm beenden)
 * Jeder Thread hat eigene Frame-Sätze und eigenen Einzelschritt. Hält ein Thread an, bleiben
 * die übrigen an ihrem nächsten Haken stehen, bis er weiterläuft.
 */
#define _XOPEN_SOURCE 600
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <poll.h>

void FPC_ZOS_A2E(unsigned char *p, long n);
void FPC_ZOS_E2A(unsigned char *p, long n);

/* Beschreibungen, wie zdbg-instrument.py sie erzeugt */
struct zt;
struct zf { const char *name; int offset; int pad; const struct zt *type; long long value; };
struct zt { const char *name; int kind; int size; const struct zt *base; int count; int low; const struct zf *fields; };
struct zv { const char *name; const struct zt *type; int flags; int pad; };
struct zg { const char *name; void *addr; const struct zt *type; };
struct zm { int n; const struct zg *globals; };
struct zfn { const char *name; const char *file; int nvars; int pad; const struct zv *vars; const struct zm *mod; };
struct zrec { struct zrec *prev; const struct zfn *fn; int line; int pad; void *vars[1]; };

enum { K_UNKNOWN, K_INT, K_UINT, K_FLOAT, K_BOOL, K_CHAR, K_PTR, K_STRUCT, K_ARRAY, K_ANSI,
       K_SHORT, K_ENUM, K_CLASS, K_WCHAR, K_USTR, K_SET, K_REF };

static int state;                 /* 0 unbekannt, 1 aus, 2 an */
static int outfd = -1, cmdfd = -1;
static int in_w = -1;             /* Schreibende der Standardeingabe des Programms */
static pthread_mutex_t mu = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t outmu = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t cv = PTHREAD_COND_INITIALIZER;
static pthread_t out_thread, cmd_thread;
static int out_pipe = -1;
static pthread_key_t thr_key;

/* Ablaufsteuerung je Thread; ein Thread hält an, die anderen bleiben an ihrem
   nächsten Haken stehen, bis er weiterläuft (mu) */
enum { M_RUN, M_IN, M_OVER, M_OUT };
#define MAXTHR 64
struct thr {
  pthread_t id;
  int num;                        /* 1 = Hauptprogramm */
  struct zrec *head;              /* innerster Frame-Satz */
  int mode;
  int step_depth;
  struct zrec *stop_rec;
  int stop_line;
  int skip_same;                  /* nach dem Fortsetzen: gleiche Stelle nicht erneut melden */
};
static struct thr thrs[MAXTHR];
static int nthr;
static volatile int pause_req;
static volatile int stopped;      /* Nummer des stehenden Threads, 0 = keiner */
static volatile int resume_cmd;   /* 0 = keiner, sonst 'C','N','I','O' */
static int started;               /* RUN empfangen */
static int stop_at_entry;

/* Haltepunkte: Datei (Basisname, ohne Groß-/Kleinschreibung) und Zeile */
#define MAXBP 512
static struct { char file[64]; int line; } bps[MAXBP];
static int nbp;
static unsigned char bpmask[512];  /* Bit je (Zeile mod 4096): schnelle Ablehnung */

/* ---------- Ausgabe an den Adapter ---------- */
static void send_raw(const char *s, size_t n)
{
  unsigned char buf[1024];
  pthread_mutex_lock(&outmu);
  while (n > 0) {
    size_t k = n < sizeof buf ? n : sizeof buf;
    memcpy(buf, s, k);
    FPC_ZOS_A2E(buf, (long)k);
    size_t off = 0;
    while (off < k) {
      ssize_t w = write(outfd, buf + off, k - off);
      if (w <= 0) {
        pthread_mutex_unlock(&outmu);
        return;
      }
      off += (size_t)w;
    }
    s += k;
    n -= k;
  }
  pthread_mutex_unlock(&outmu);
}

/* dynamischer Puffer */
struct sb { char *p; size_t n, cap; };
static void sb_add(struct sb *b, const char *s, size_t n)
{
  if (b->n + n + 1 > b->cap) {
    size_t c = b->cap ? b->cap * 2 : 256;
    while (c < b->n + n + 1)
      c *= 2;
    char *q = realloc(b->p, c);
    if (!q)
      return;
    b->p = q;
    b->cap = c;
  }
  memcpy(b->p + b->n, s, n);
  b->n += n;
  b->p[b->n] = 0;
}
static void sb_str(struct sb *b, const char *s) { sb_add(b, s, strlen(s)); }
static void sb_fmt(struct sb *b, const char *fmt, ...) __attribute__((format(printf, 2, 3)));
#include <stdarg.h>
static void sb_fmt(struct sb *b, const char *fmt, ...)
{
  char tmp[512];
  va_list ap;
  va_start(ap, fmt);
  int n = vsnprintf(tmp, sizeof tmp, fmt, ap);
  va_end(ap);
  if (n > 0)
    sb_add(b, tmp, (size_t)(n < (int)sizeof tmp ? n : (int)sizeof tmp - 1));
}
/* JSON-String (nur ASCII; alles andere als \u00XX) */
static void sb_json(struct sb *b, const char *s, size_t n)
{
  sb_add(b, "\"", 1);
  for (size_t i = 0; i < n; i++) {
    unsigned char c = (unsigned char)s[i];
    if (c == '"' || c == '\\') {
      char e[2] = { '\\', (char)c };
      sb_add(b, e, 2);
    } else if (c == '\n') {
      sb_add(b, "\\n", 2);
    } else if (c < 32 || c > 126) {
      sb_fmt(b, "\\u%04x", c);
    } else {
      sb_add(b, (const char *)&c, 1);
    }
  }
  sb_add(b, "\"", 1);
}
static void send_sb(struct sb *b)
{
  sb_add(b, "\n", 1);
  send_raw(b->p, b->n);
  free(b->p);
  b->p = 0;
  b->n = b->cap = 0;
}

/* ---------- Werte formatieren ---------- */
static long long rd_int(const void *p, int size, int sign)
{
  switch (size) {
  case 1: return sign ? (long long)*(const int8_t *)p : (long long)*(const uint8_t *)p;
  case 2: { int16_t v; memcpy(&v, p, 2); return sign ? v : (uint16_t)v; }
  case 4: { int32_t v; memcpy(&v, p, 4); return sign ? v : (uint32_t)v; }
  default: { int64_t v; memcpy(&v, p, 8); return v; }
  }
}

static int expandable(const struct zt *t, const void *addr)
{
  if (!t)
    return 0;
  switch (t->kind) {
  case K_STRUCT: return t->count > 0;
  case K_ARRAY: return t->count > 0;
  case K_CLASS: case K_PTR: { void *p; memcpy(&p, addr, 8); return p != 0 && t->base && t->base->kind != K_UNKNOWN; }
  case K_REF: { void *p; memcpy(&p, addr, 8); return p != 0 && expandable(t->base, p); }
  default: return 0;
  }
}

/* Wert von Typ t an addr als Text */
static void fmt_value(struct sb *b, const struct zt *t, const void *addr)
{
  char tmp[128];
  if (!t || !addr) {
    sb_str(b, "?");
    return;
  }
  switch (t->kind) {
  case K_INT: sb_fmt(b, "%lld", rd_int(addr, t->size, 1)); break;
  case K_UINT: sb_fmt(b, "%llu", (unsigned long long)rd_int(addr, t->size, 0)); break;
  case K_FLOAT:
    if (t->size == 4) { float f; memcpy(&f, addr, 4); sb_fmt(b, "%.7g", (double)f); }
    else if (t->size == 8) { double d; memcpy(&d, addr, 8); sb_fmt(b, "%.15g", d); }
    else sb_str(b, "(float)");
    break;
  case K_BOOL: sb_str(b, rd_int(addr, t->size, 0) ? "True" : "False"); break;
  case K_CHAR: {
    unsigned char c = *(const unsigned char *)addr;
    if (c >= 32 && c < 127) sb_fmt(b, "'%c'", c); else sb_fmt(b, "#%u", c);
    break;
  }
  case K_WCHAR: sb_fmt(b, "#%u", (unsigned)rd_int(addr, 2, 0)); break;
  case K_ENUM: {
    long long v = rd_int(addr, t->size ? t->size : 4, 0);
    for (int i = 0; i < t->count; i++)
      if (t->fields[i].value == v) { sb_str(b, t->fields[i].name); return; }
    sb_fmt(b, "%lld", v);
    break;
  }
  case K_ANSI: {
    const char *s;
    memcpy(&s, addr, 8);
    if (!s) { sb_str(b, "''"); break; }
    size_t n = 0;
    while (n < 200 && s[n])
      n++;
    sb_str(b, "'");
    for (size_t i = 0; i < n; i++) {
      unsigned char c = (unsigned char)s[i];
      if (c == '\'') sb_str(b, "''");
      else if (c >= 32 && c < 127) sb_add(b, (const char *)&c, 1);
      else { snprintf(tmp, sizeof tmp, "'#%u'", c); sb_str(b, tmp); }
    }
    sb_str(b, n == 200 ? "'..." : "'");
    break;
  }
  case K_SHORT: {
    const unsigned char *s = addr;
    sb_str(b, "'");
    for (unsigned i = 1; i <= s[0]; i++) {
      unsigned char c = s[i];
      if (c == '\'') sb_str(b, "''");
      else if (c >= 32 && c < 127) sb_add(b, (const char *)&c, 1);
      else { snprintf(tmp, sizeof tmp, "'#%u'", c); sb_str(b, tmp); }
    }
    sb_str(b, "'");
    break;
  }
  case K_USTR: {
    const uint16_t *s;
    memcpy(&s, addr, 8);
    if (!s) { sb_str(b, "''"); break; }
    sb_str(b, "'");
    for (int i = 0; i < 200 && s[i]; i++) {
      uint16_t c = s[i];
      if (c >= 32 && c < 127 && c != '\'') { char ch = (char)c; sb_add(b, &ch, 1); }
      else if (c == '\'') sb_str(b, "''");
      else { snprintf(tmp, sizeof tmp, "'#%u'", c); sb_str(b, tmp); }
    }
    sb_str(b, "'");
    break;
  }
  case K_PTR: case K_CLASS: {
    void *p;
    memcpy(&p, addr, 8);
    if (!p) sb_str(b, "nil");
    else sb_fmt(b, "%s$%llX", t->kind == K_CLASS ? "Objekt " : "", (unsigned long long)(uintptr_t)p);
    break;
  }
  case K_REF: {
    void *p;
    memcpy(&p, addr, 8);
    if (!p) sb_str(b, "nil");
    else fmt_value(b, t->base, p);
    break;
  }
  case K_STRUCT: sb_fmt(b, "(%s)", t->name ? t->name : "record"); break;
  case K_ARRAY:
    if (t->count > 0) sb_fmt(b, "array[%d..%d]", t->low, t->low + t->count - 1);
    else sb_str(b, "array");
    break;
  case K_SET: default: {
    const unsigned char *p = addr;
    int n = t->size > 0 && t->size <= 32 ? t->size : 8;
    sb_str(b, "$");
    for (int i = 0; i < n; i++) sb_fmt(b, "%02X", p[i]);
    break;
  }
  }
}

/* ein Eintrag der Variablenliste */
static void json_var(struct sb *b, const char *name, const struct zt *t, const void *addr, int *first)
{
  if (!*first)
    sb_str(b, ",");
  *first = 0;
  sb_str(b, "{\"name\":");
  sb_json(b, name, strlen(name));
  struct sb v = { 0 };
  fmt_value(&v, t, addr);
  sb_str(b, ",\"value\":");
  sb_json(b, v.p ? v.p : "", v.n);
  free(v.p);
  sb_str(b, ",\"type\":");
  const char *tn = t && t->name ? t->name : "";
  sb_json(b, tn, strlen(tn));
  if (expandable(t, addr))
    sb_fmt(b, ",\"ref\":\"%llX:%llX\"", (unsigned long long)(uintptr_t)t, (unsigned long long)(uintptr_t)addr);
  sb_str(b, "}");
}

/* Kinder eines strukturierten Werts */
static void json_children(struct sb *b, const struct zt *t, const void *addr)
{
  int first = 1;
  char nm[32];
  sb_str(b, "[");
  if (t->kind == K_REF) {
    void *p;
    memcpy(&p, addr, 8);
    t = t->base;
    addr = p;
  }
  if (t->kind == K_PTR || t->kind == K_CLASS) {
    void *p;
    memcpy(&p, addr, 8);
    if (t->kind == K_CLASS && t->base && t->base->kind == K_STRUCT) {
      t = t->base;
      addr = p;
    } else {
      json_var(b, "^", t->base, p, &first);
      sb_str(b, "]");
      return;
    }
  }
  if (t->kind == K_STRUCT) {
    for (int i = 0; i < t->count; i++) {
      if (t->fields[i].name && t->fields[i].name[0] == '_')
        continue; /* _vptr u. ä. */
      json_var(b, t->fields[i].name, t->fields[i].type, (const char *)addr + t->fields[i].offset, &first);
    }
  } else if (t->kind == K_ARRAY && t->base) {
    int es = t->base->size > 0 ? t->base->size : (t->count ? t->size / t->count : 1);
    int n = t->count > 1000 ? 1000 : t->count;
    for (int i = 0; i < n; i++) {
      snprintf(nm, sizeof nm, "[%d]", t->low + i);
      json_var(b, nm, t->base, (const char *)addr + (long)i * es, &first);
    }
  }
  sb_str(b, "]");
}

static struct thr *thr_by_num(int n)
{
  return n >= 1 && n <= nthr ? &thrs[n - 1] : 0;
}

static struct zrec *frame_at(struct thr *t, int k)
{
  struct zrec *r = t ? t->head : 0;
  while (r && k-- > 0)
    r = r->prev;
  return r;
}

static const char *basename_of(const char *f)
{
  const char *s = strrchr(f, '/');
  return s ? s + 1 : f;
}

/* JSON-String ab dem Anführungszeichen dekodieren (\n, \", \\, \uXXXX bis 255) */
static size_t json_decode(const char *s, char *out, size_t cap)
{
  size_t n = 0;
  if (*s != '"')
    return 0;
  for (s++; *s && *s != '"' && n < cap; s++) {
    if (*s != '\\') {
      out[n++] = *s;
      continue;
    }
    s++;
    switch (*s) {
    case 'n': out[n++] = '\n'; break;
    case 't': out[n++] = '\t'; break;
    case 'r': out[n++] = '\r'; break;
    case 'u': {
      unsigned v = 0;
      for (int i = 1; i <= 4 && s[i]; i++)
        v = v * 16 + (unsigned)(s[i] <= '9' ? s[i] - '0' : (s[i] | 0x20) - 'a' + 10);
      out[n++] = (char)(v & 0xFF);
      s += 4;
      break;
    }
    case 0: return n;
    default: out[n++] = *s; break;
    }
  }
  return n;
}

/* ---------- Befehle ---------- */
static void do_cmd(char *line)
{
  struct sb b = { 0 };
  char *sp = strchr(line, ' ');
  char *arg = sp ? sp + 1 : line + strlen(line);
  if (sp)
    *sp = 0;
  if (!strcmp(line, "B")) {
    /* B <datei> <zeile> ... : Haltepunkte dieser Datei ersetzen */
    char *f = strtok(arg, " ");
    if (!f)
      return;
    pthread_mutex_lock(&mu);
    int k = 0;
    for (int i = 0; i < nbp; i++)
      if (strcasecmp(bps[i].file, f) != 0)
        bps[k++] = bps[i];
    nbp = k;
    char *t;
    while ((t = strtok(0, " ")) && nbp < MAXBP) {
      snprintf(bps[nbp].file, sizeof bps[nbp].file, "%s", f);
      bps[nbp].line = atoi(t);
      nbp++;
    }
    memset(bpmask, 0, sizeof bpmask);
    for (int i = 0; i < nbp; i++)
      bpmask[(bps[i].line >> 3) & 511] |= (unsigned char)(1u << (bps[i].line & 7));
    pthread_mutex_unlock(&mu);
    return;
  }
  if (!strcmp(line, "RUN") || !strcmp(line, "RUNSTOP")) {
    pthread_mutex_lock(&mu);
    stop_at_entry = !strcmp(line, "RUNSTOP");
    started = 1;
    pthread_cond_broadcast(&cv);
    pthread_mutex_unlock(&mu);
    return;
  }
  if (strlen(line) == 1 && strchr("CNIO", line[0])) {
    pthread_mutex_lock(&mu);
    if (stopped) {
      resume_cmd = line[0];
      pthread_cond_broadcast(&cv);
    }
    pthread_mutex_unlock(&mu);
    return;
  }
  if (!strcmp(line, "P")) {
    pause_req = 1;
    return;
  }
  if (!strcmp(line, "X"))
    _exit(143);
  if (!strcmp(line, "IN")) {
    /* IN <json-string>: an die Standardeingabe des Programms */
    char buf[4096];
    size_t n = json_decode(arg, buf, sizeof buf);
    if (in_w >= 0 && n > 0)
      write(in_w, buf, n);
    return;
  }
  if (!strcmp(line, "EOF")) {
    if (in_w >= 0)
      close(in_w);
    in_w = -1;
    return;
  }
  /* Abfragen nur, wenn ein Thread steht (die anderen warten an ihrem nächsten Haken) */
  char *id = strtok(arg, " ");
  if (!id)
    return;
  sb_fmt(&b, "@@Z R %s ", id);
  if (!stopped) {
    sb_str(&b, "null");
    send_sb(&b);
    return;
  }
  if (!strcmp(line, "H")) {
    int first = 1;
    sb_str(&b, "[");
    for (int i = 0; i < nthr; i++) {
      if (!thrs[i].head)
        continue;
      if (!first)
        sb_str(&b, ",");
      first = 0;
      if (thrs[i].num == 1)
        sb_fmt(&b, "{\"id\":1,\"name\":\"Hauptprogramm\"}");
      else
        sb_fmt(&b, "{\"id\":%d,\"name\":\"Thread %d\"}", thrs[i].num, thrs[i].num);
    }
    sb_str(&b, "]");
  } else if (!strcmp(line, "T")) {
    char *ts = strtok(0, " ");
    struct thr *t = thr_by_num(ts ? atoi(ts) : stopped);
    int first = 1;
    sb_str(&b, "[");
    for (struct zrec *r = t ? t->head : 0; r; r = r->prev) {
      if (r->line == 0 && r != t->head)
        continue; /* noch ohne Zeile (Einstieg "main" vor PASCALMAIN) */
      if (!first)
        sb_str(&b, ",");
      first = 0;
      sb_str(&b, "{\"name\":");
      sb_json(&b, r->fn->name, strlen(r->fn->name));
      sb_str(&b, ",\"file\":");
      sb_json(&b, r->fn->file, strlen(r->fn->file));
      sb_fmt(&b, ",\"line\":%d}", r->line);
    }
    sb_str(&b, "]");
  } else if (!strcmp(line, "L") || !strcmp(line, "G")) {
    char *ts = strtok(0, " ");
    char *fs = strtok(0, " ");
    struct zrec *r = frame_at(thr_by_num(ts ? atoi(ts) : stopped), fs ? atoi(fs) : 0);
    int first = 1;
    sb_str(&b, "[");
    if (r && line[0] == 'L')
      for (int i = 0; i < r->fn->nvars; i++)
        json_var(&b, r->fn->vars[i].name, r->fn->vars[i].type, r->vars[i], &first);
    if (r && line[0] == 'G' && r->fn->mod)
      for (int i = 0; i < r->fn->mod->n; i++)
        json_var(&b, r->fn->mod->globals[i].name, r->fn->mod->globals[i].type, r->fn->mod->globals[i].addr, &first);
    sb_str(&b, "]");
  } else if (!strcmp(line, "V")) {
    char *ts = strtok(0, " ");
    char *colon = ts ? strchr(ts, ':') : 0;
    if (colon) {
      *colon = 0;
      const struct zt *t = (const struct zt *)(uintptr_t)strtoull(ts, 0, 16);
      const void *a = (const void *)(uintptr_t)strtoull(colon + 1, 0, 16);
      json_children(&b, t, a);
    } else {
      sb_str(&b, "[]");
    }
  } else {
    sb_str(&b, "null");
  }
  send_sb(&b);
}

static void *cmd_main(void *u)
{
  (void)u;
  char buf[8192];
  size_t n = 0;
  for (;;) {
    ssize_t r = read(cmdfd, buf + n, sizeof buf - 1 - n);
    if (r <= 0)
      _exit(143); /* Adapter weg: Programm beenden */
    FPC_ZOS_E2A((unsigned char *)buf + n, (long)r);
    n += (size_t)r;
    for (;;) {
      char *nl = memchr(buf, '\n', n);
      if (!nl)
        break;
      *nl = 0;
      if (nl > buf && nl[-1] == '\r')
        nl[-1] = 0;
      do_cmd(buf);
      size_t used = (size_t)(nl - buf) + 1;
      memmove(buf, buf + used, n - used);
      n -= used;
    }
    if (n == sizeof buf - 1)
      n = 0; /* überlange Zeile verwerfen */
  }
  return 0;
}

/* Programmausgabe aus der Pipe weitergeben, bis sie leer ist (Leseende nicht blockierend).
   Unter drainmu, damit STOP/END erst nach der Ausgabe davor hinausgehen. 0 = Pipe zu. */
static pthread_mutex_t drainmu = PTHREAD_MUTEX_INITIALIZER;
static int drain(void)
{
  char buf[2048];
  int open = 1;
  pthread_mutex_lock(&drainmu);
  for (;;) {
    ssize_t r = read(out_pipe, buf, sizeof buf);
    if (r == 0)
      open = 0;
    if (r <= 0)
      break;
    struct sb b = { 0 };
    sb_str(&b, "@@Z O ");
    sb_json(&b, buf, (size_t)r);
    send_sb(&b);
  }
  pthread_mutex_unlock(&drainmu);
  return open;
}

static void *out_main(void *u)
{
  (void)u;
  struct pollfd pf = { out_pipe, POLLIN, 0 };
  for (;;) {
    pf.revents = 0;
    if (poll(&pf, 1, -1) < 0 && errno != EINTR)
      break;
    if (!drain())
      break;
  }
  return 0;
}

/* Programmende. FpExit ist auf z/OS _exit (atexit läuft nicht): die RTL ruft
   FPC_ZOS_DBG_EXIT vorher selbst; atexit deckt Programme ab, die exit() rufen. */
void FPC_ZOS_DBG_EXIT(void)
{
  if (state != 2)
    return;
  state = 1;
  /* Programmausgabe abschließen: Schreibenden schließen, Rest weitergeben */
  fflush(stdout);
  fflush(stderr);
  close(1);
  close(2);
  drain();
  send_raw("@@Z END\n", 8);
}

static void at_end(void)
{
  FPC_ZOS_DBG_EXIT();
}

/* Haken in System_exit der z/OS-RTL (rtl/zos/system.pp) */
extern void (*FPC_ZOS_DBG_EXITHOOK)(void);

static struct thr *self_thr(void)
{
  struct thr *t = pthread_getspecific(thr_key);
  if (t)
    return t;
  pthread_mutex_lock(&mu);
  if (nthr < MAXTHR) {
    t = &thrs[nthr];
    memset(t, 0, sizeof *t);
    t->id = pthread_self();
    t->num = ++nthr;
    if (t->num == 1 && stop_at_entry)
      t->mode = M_IN;
  }
  pthread_mutex_unlock(&mu);
  if (t)
    pthread_setspecific(thr_key, t);
  return t;
}

static void init(void)
{
  const char *e = getenv("ZDBG");
  if (!e || strcmp(e, "1") != 0) {
    state = 1;
    return;
  }
  outfd = dup(1);
  cmdfd = dup(0);
  int p[2], ip[2];
  if (outfd < 0 || cmdfd < 0 || pipe(p) != 0 || pipe(ip) != 0 ||
      pthread_key_create(&thr_key, 0) != 0) {
    state = 1;
    return;
  }
  /* Programmausgabe über eine Pipe, Standardeingabe aus einer Pipe (IN-Befehle) */
  dup2(p[1], 1);
  dup2(p[1], 2);
  close(p[1]);
  out_pipe = p[0];
  fcntl(out_pipe, F_SETFL, fcntl(out_pipe, F_GETFL) | O_NONBLOCK);
  dup2(ip[0], 0);
  close(ip[0]);
  in_w = ip[1];
  state = 2;
  pthread_create(&out_thread, 0, out_main, 0);
  pthread_create(&cmd_thread, 0, cmd_main, 0);
  FPC_ZOS_DBG_EXITHOOK = FPC_ZOS_DBG_EXIT;
  atexit(at_end);
  send_raw("@@Z READY\n", 10);
  /* auf Haltepunkte und RUN warten */
  pthread_mutex_lock(&mu);
  while (!started)
    pthread_cond_wait(&cv, &mu);
  pthread_mutex_unlock(&mu);
}

static int depth_of(struct zrec *r)
{
  int d = 0;
  for (; r; r = r->prev)
    d++;
  return d;
}

static int bp_hit(struct zrec *r, int line)
{
  if (!(bpmask[(line >> 3) & 511] & (1u << (line & 7))))
    return 0;
  const char *f = basename_of(r->fn->file);
  pthread_mutex_lock(&mu);
  int hit = 0;
  for (int i = 0; i < nbp && !hit; i++)
    hit = bps[i].line == line && strcasecmp(bps[i].file, f) == 0;
  pthread_mutex_unlock(&mu);
  return hit;
}

/* Steht ein anderer Thread, an diesem Haken warten. */
static void wait_while_stopped(struct thr *t)
{
  if (!stopped || stopped == t->num)
    return;
  pthread_mutex_lock(&mu);
  while (stopped && stopped != t->num)
    pthread_cond_wait(&cv, &mu);
  pthread_mutex_unlock(&mu);
}

static void stop(struct thr *t, struct zrec *r, int line, const char *why)
{
  fflush(stdout);
  pthread_mutex_lock(&mu);
  while (stopped && stopped != t->num)
    pthread_cond_wait(&cv, &mu);
  stopped = t->num;
  resume_cmd = 0;
  pause_req = 0;
  pthread_mutex_unlock(&mu);
  drain(); /* Ausgabe bis hierher vor der Meldung */
  struct sb b = { 0 };
  sb_fmt(&b, "@@Z STOP %s %d %d ", why, line, t->num);
  sb_json(&b, r->fn->file, strlen(r->fn->file));
  send_sb(&b);
  pthread_mutex_lock(&mu);
  while (!resume_cmd)
    pthread_cond_wait(&cv, &mu);
  int c = resume_cmd;
  resume_cmd = 0;
  t->stop_rec = r;
  t->stop_line = line;
  t->skip_same = 1;
  t->step_depth = depth_of(r);
  t->mode = c == 'I' ? M_IN : c == 'N' ? M_OVER : c == 'O' ? M_OUT : M_RUN;
  stopped = 0;
  pthread_cond_broadcast(&cv);
  pthread_mutex_unlock(&mu);
}

void FPC_ZOS_DBG_ENTER(struct zrec *r)
{
  if (state != 2) {
    if (state == 1)
      return;
    init();
    if (state != 2)
      return;
  }
  struct thr *t = self_thr();
  if (!t)
    return;
  r->line = 0;
  /* Sätze beendeter Routinen verwerfen: der Stack wächst nach unten, ein lebender
     Aufrufer liegt oberhalb des neuen Satzes (Routinen, die aus nicht instrumentiertem
     Code aufgerufen wurden und zurückgekehrt sind, tragen sich nicht aus) */
  while (t->head && (uintptr_t)t->head <= (uintptr_t)r)
    t->head = t->head->prev;
  r->prev = t->head;
  t->head = r;
}

void FPC_ZOS_DBG_LINE(struct zrec *r, int line)
{
  if (state != 2)
    return;
  struct thr *t = self_thr();
  if (!t)
    return;
  r->line = line;
  t->head = r;
  if (stopped)
    wait_while_stopped(t);
  if (t->skip_same) {
    /* eine Zeile kann aus mehreren Grundblöcken bestehen, auch nach Aufrufen aus ihr:
       erst ein Zeilenwechsel in derselben Routine oder ihr Verlassen beendet das */
    if (r == t->stop_rec) {
      if (line == t->stop_line)
        return;
      t->skip_same = 0;
    } else if (depth_of(r) < t->step_depth) {
      t->skip_same = 0;
    }
  }
  int m = t->mode;
  if (m == M_RUN && !pause_req && !(bpmask[(line >> 3) & 511] & (1u << (line & 7))))
    return; /* schneller Weg */
  if (pause_req) {
    stop(t, r, line, "pause");
    return;
  }
  if (m != M_RUN) {
    int d = depth_of(r);
    if (m == M_IN || (m == M_OVER && d <= t->step_depth) || (m == M_OUT && d < t->step_depth)) {
      stop(t, r, line, t->stop_rec ? "step" : "entry");
      return;
    }
  }
  if (bp_hit(r, line))
    stop(t, r, line, "breakpoint");
}
