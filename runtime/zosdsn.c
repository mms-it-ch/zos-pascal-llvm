/* zosdsn.c - MVS-Datasets für die Datei-Routinen der RTL (Do_Open, Do_Read, ...).
 *
 * Datasets haben keine Dateideskriptoren (fileno = -1); sie gehen nur über die
 * C-Streams. Die RTL leitet Namen der Form
 *     //'HLQ.NAME'   //'HLQ.PDS(MEMBER)'   //NAME (mit TSO-Präfix)
 *     //DD:DDNAME    DD:DDNAME
 * hierher; ein Zusatz nach einem Komma geht als fopen-Attribut mit, z. B.
 *     //'HLQ.NEU',recfm=fb,lrecl=80,space=(trk,(5,5))
 * Die Handles sind eigene Nummern ab DSN_FIRST (keine Dateideskriptoren).
 * Bibliotheken: ein neues PDS entsteht mit dem ersten Member, wenn space
 * Directory-Blöcke angibt (space=(trk,(1,1,5))). fopen kennt dsntype nicht:
 * mit dsntype=library (PDSE) bzw. dsntype=pds legt diese Schicht die
 * Bibliothek vorher mit dynalloc an (recfm, lrecl, blksize, space aus den
 * Attributen) und gibt fopen die Attribute ohne dsntype weiter.
 *
 * Textdateien: Textmodus der C-Laufzeit (ein Satz = eine Zeile; FB wird beim
 * Schreiben mit Leerzeichen aufgefüllt und beim Lesen gekürzt, VB behält die
 * Länge), dazu Umwandlung ISO-8859-1 <-> EBCDIC, Zeilenende LF <-> X'15'
 * (wie iconv unter z/OS UNIX). EBCDIC-Codepage (CCSID): Standard IBM-1047, global
 * über die Umgebungsvariable ZOS_CCSID oder FPC_ZOS_CCSID_SET_DEFAULT, je Datei über
 * den Zusatz ",ccsid=NNN" im Namen oder FPC_ZOS_DSN_SET_CCSID (Unit zosebcdic);
 * Tabellen: zosccsid.h (scripts/gen-ccsid.py). Binärdateien: Bytestrom ("rb"/"wb"), ohne
 * Umwandlung (FB: Sätze hintereinander; kurze Sätze füllt die C-Laufzeit mit
 * X'00' auf).
 *
 * Batch: sind die Deskriptoren 0/1/2 nicht offen und die DD-Anweisung kein
 * z/OS-UNIX-Pfad (SYSOUT=*, Dataset, DD *), übernimmt diese Schicht die
 * Standard-Handles (FPC_ZOS_DSN_ADOPT, aus zoscompat.c).
 */
#define _EXT 1
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <dynit.h>
#include <pwd.h>
#include <stdint.h>
#include <strings.h>
#include <unistd.h>

#include "zosccsid.h"

#define DSN_FIRST 0x7F000000
#define DSN_MAX 256

struct dsn {
  FILE *f;
  int text;
  const struct zos_ccsid *cs;   /* Textdateien: Codepage der Umwandlung */
};

static struct dsn tab[DSN_MAX];
static struct dsn stdtab[3];   /* Batch: Handles 0, 1, 2 */

/* IBM-1047 (erster Eintrag von zosccsid.h, gleich der früher auf z/OS mit iconv
 * gemessenen Tabelle): DD-Namen in der TIOT und Standard der Textdateien */
#define a2e_1047 (zos_ccsids[0].a2e)

static const struct zos_ccsid *defcs;  /* Standard (ZOS_CCSID), beim ersten Gebrauch */

static const struct zos_ccsid *find_ccsid(long ccsid)
{
  for (size_t i = 0; i < ZOS_NCCSIDS; i++)
    if (zos_ccsids[i].ccsid == ccsid)
      return &zos_ccsids[i];
  return 0;
}

/* Standard-CCSID: ZOS_CCSID (Zahl, auch "IBM-273"/"IBM273"), sonst 1047. Ein
 * unbekannter Wert wird einmal auf stderr gemeldet; es bleibt bei 1047. */
static const struct zos_ccsid *default_ccsid(void)
{
  if (!defcs) {
    const char *v = getenv("ZOS_CCSID");
    defcs = &zos_ccsids[0];
    if (v && *v) {
      const char *p = v;
      const struct zos_ccsid *c;
      if (strncasecmp(p, "IBM", 3) == 0) {
        p += 3;
        if (*p == '-')
          p++;
      }
      c = find_ccsid(strtol(p, 0, 10));
      if (c)
        defcs = c;
      else
        fprintf(stderr, "ZOS_CCSID=%s wird nicht unterstützt, es gilt 1047\n", v);
    }
  }
  return defcs;
}

static struct dsn *get(int h)
{
  if (h >= DSN_FIRST && h < DSN_FIRST + DSN_MAX && tab[h - DSN_FIRST].f)
    return &tab[h - DSN_FIRST];
  if (h >= 0 && h <= 2 && stdtab[h].f)
    return &stdtab[h];
  return 0;
}

/* Name eines Datasets oder einer DD-Anweisung? */
int FPC_ZOS_DSN_NAME(const char *p)
{
  return (p[0] == '/' && p[1] == '/') || strncasecmp(p, "DD:", 3) == 0;
}

/* Handle dieser Schicht? */
int FPC_ZOS_DSN_HANDLE(int h)
{
  return get(h) != 0;
}

/* Wert eines Attributs key=... aus der fopen-Attributliste (Kopie in buf) */
static int attr_value(const char *attrs, const char *key, char *buf, size_t n)
{
  size_t kl = strlen(key);
  const char *p = attrs;
  while (p && *p) {
    if (strncasecmp(p, key, kl) == 0 && p[kl] == '=') {
      const char *v = p + kl + 1, *e = v;
      int depth = 0;
      while (*e && (depth > 0 || *e != ',')) {
        if (*e == '(') depth++;
        if (*e == ')') depth--;
        e++;
      }
      if ((size_t)(e - v) >= n)
        return 0;
      memcpy(buf, v, (size_t)(e - v));
      buf[e - v] = 0;
      return 1;
    }
    /* zum nächsten Attribut (Klammern überspringen) */
    {
      int depth = 0;
      while (*p && (depth > 0 || *p != ',')) {
        if (*p == '(') depth++;
        if (*p == ')') depth--;
        p++;
      }
      if (*p == ',')
        p++;
    }
  }
  return 0;
}

/* Attribut key=... aus der Liste entfernen (an Ort und Stelle) */
static void attr_remove(char *attrs, const char *key)
{
  size_t kl = strlen(key);
  char *p = attrs;
  while (*p) {
    char *start = p;
    int depth = 0;
    while (*p && (depth > 0 || *p != ',')) {
      if (*p == '(') depth++;
      if (*p == ')') depth--;
      p++;
    }
    if (strncasecmp(start, key, kl) == 0 && start[kl] == '=') {
      if (*p == ',')
        p++;
      memmove(start, p, strlen(p) + 1);
      p = start;
    } else if (*p == ',')
      p++;
  }
  kl = strlen(attrs);
  if (kl && attrs[kl - 1] == ',')
    attrs[kl - 1] = 0;
}

/* Bibliothek (PDS/PDSE) mit dynalloc anlegen; name = //'DSN(MEMBER)' oder
 * //DSN(MEMBER) (TSO-Präfix = User-ID). Ist sie schon da, schlägt dynalloc
 * fehl, das ist in Ordnung (fopen folgt). */
static void alloc_library(const char *name, const char *attrs, unsigned char dsntype)
{
  char dsn[64], v[64];
  const char *p = name + 2;
  size_t k = 0;
  __dyn_t ip;
  if (*p == '\'') {
    p++;
  } else {
    struct passwd *pw = getpwuid(geteuid());
    if (!pw)
      return;
    for (const char *u = pw->pw_name; *u && k < 8; u++)
      dsn[k++] = (char)toupper((unsigned char)*u);
    dsn[k++] = '.';
  }
  for (; *p && *p != '(' && *p != '\'' && k < sizeof dsn - 1; p++)
    dsn[k++] = (char)toupper((unsigned char)*p);
  dsn[k] = 0;
  dyninit(&ip);
  ip.__dsname = dsn;
  ip.__status = __DISP_NEW;
  ip.__normdisp = __DISP_CATLG;
  ip.__conddisp = __DISP_DELETE;
  ip.__dsorg = __DSORG_PO;
  ip.__dsntype = dsntype;
  ip.__alcunit = __TRK;
  ip.__primary = 1;
  ip.__secondary = 1;
  ip.__dirblk = 5;
  ip.__recfm = _VB_;
  ip.__lrecl = 255;
  if (attr_value(attrs, "recfm", v, sizeof v)) {
    if (strcasecmp(v, "f") == 0) ip.__recfm = _F_;
    else if (strcasecmp(v, "fb") == 0) ip.__recfm = _FB_;
    else if (strcasecmp(v, "v") == 0) ip.__recfm = _V_;
    else if (strcasecmp(v, "vb") == 0) ip.__recfm = _VB_;
    else if (strcasecmp(v, "u") == 0) ip.__recfm = _U_;
  }
  if (attr_value(attrs, "lrecl", v, sizeof v))
    ip.__lrecl = (unsigned short)atoi(v);
  if (attr_value(attrs, "blksize", v, sizeof v))
    ip.__blksize = (short)atoi(v);
  /* space=(trk|cyl,(p[,s[,d]])) */
  if (attr_value(attrs, "space", v, sizeof v)) {
    int pr = 0, se = 0, di = 0;
    char unit[8] = "";
    if (sscanf(v, "(%7[a-zA-Z],(%d,%d,%d))", unit, &pr, &se, &di) >= 2 ||
        sscanf(v, "(%7[a-zA-Z],%d)", unit, &pr) == 2) {
      if (strcasecmp(unit, "cyl") == 0)
        ip.__alcunit = __CYL;
      if (pr > 0) ip.__primary = pr;
      if (se > 0) ip.__secondary = se;
      if (di > 0) ip.__dirblk = di;
    }
  }
  if (dynalloc(&ip) == 0) {
    __dyn_t fr;
    dyninit(&fr);
    fr.__dsname = dsn;
    dynfree(&fr);
  }
}

/* mode: 0 lesen, 1 schreiben (neu), 2 lesen/schreiben, 3 anhängen,
 * 4 lesen/schreiben (neu).
 * Ergebnis: Handle oder -1 (errno gesetzt). */
int FPC_ZOS_DSN_OPEN(const char *name, int mode, int text)
{
  static const char *const modes[2][5] = {
    { "rb", "wb", "rb+", "ab", "wb+" },
    { "r", "w", "r+", "a", "w+" } };
  char fname[1100], fmode[300], attrs[260], v[16];
  const char *comma;
  const struct zos_ccsid *cs = 0;
  size_t len;
  int i;
  if (mode < 0 || mode > 4) {
    errno = EINVAL;
    return -1;
  }
  /* Zusatz nach dem Namen (außerhalb von Hochkommas) = fopen-Attribute */
  comma = 0;
  for (const char *q = name, *quote = 0; *q; q++) {
    if (*q == '\'')
      quote = quote ? 0 : q;
    else if (*q == ',' && !quote) {
      comma = q;
      break;
    }
  }
  len = comma ? (size_t)(comma - name) : strlen(name);
  if (len >= sizeof fname) {
    errno = ENAMETOOLONG;
    return -1;
  }
  memcpy(fname, name, len);
  fname[len] = 0;
  attrs[0] = 0;
  if (comma) {
    if (strlen(comma + 1) >= sizeof attrs) {
      errno = EINVAL;
      return -1;
    }
    strcpy(attrs, comma + 1);
    /* ccsid=NNN: Codepage dieser Textdatei (kein fopen-Attribut) */
    if (attr_value(attrs, "ccsid", v, sizeof v)) {
      cs = find_ccsid(strtol(v, 0, 10));
      if (!cs) {
        errno = EINVAL;
        return -1;
      }
      attr_remove(attrs, "ccsid");
      if (!attrs[0])
        comma = 0;
    }
    /* Bibliothek: dsntype=library|pds kennt fopen nicht -> dynalloc */
    if (attr_value(attrs, "dsntype", v, sizeof v)) {
      if (mode != 0)
        alloc_library(fname, attrs, strcasecmp(v, "library") == 0 ? __DSNT_LIBRARY : __DSNT_PDS);
      attr_remove(attrs, "dsntype");
      if (!attrs[0])
        comma = 0;
    }
  }
  /* Neu schreiben ohne eigene Attribute: recfm=* behält die Attribute eines
   * vorhandenen Datasets (sonst legt "w" es mit Standardattributen neu an,
   * aus FB 80 würde VB 1024) */
  snprintf(fmode, sizeof fmode, "%s%s%s", modes[text != 0][mode],
           comma ? "," : (mode == 1 || mode == 4) ? ",recfm=*" : "",
           comma ? attrs : "");
  for (i = 0; i < DSN_MAX; i++)
    if (!tab[i].f)
      break;
  if (i == DSN_MAX) {
    errno = EMFILE;
    return -1;
  }
  tab[i].f = fopen(fname, fmode);
  if (!tab[i].f)
    return -1;
  tab[i].text = text != 0;
  tab[i].cs = cs ? cs : default_ccsid();
  return DSN_FIRST + i;
}

/* Standard-Handle fd (0, 1, 2) auf einen offenen Stream legen (Batch) */
void FPC_ZOS_DSN_ADOPT(int fd, FILE *f)
{
  if (fd >= 0 && fd <= 2) {
    stdtab[fd].f = f;
    stdtab[fd].text = 1;
    stdtab[fd].cs = default_ccsid();
  }
}

long FPC_ZOS_DSN_READ(int h, void *buf, long n)
{
  struct dsn *d = get(h);
  unsigned char *p = buf;
  size_t r;
  if (!d) {
    errno = EBADF;
    return -1;
  }
  r = fread(buf, 1, (size_t)n, d->f);
  if (r == 0 && ferror(d->f))
    return -1;
  if (d->text)
    for (size_t i = 0; i < r; i++)
      p[i] = d->cs->e2a[p[i]];
  return (long)r;
}

long FPC_ZOS_DSN_WRITE(int h, const void *buf, long n)
{
  struct dsn *d = get(h);
  const unsigned char *p = buf;
  unsigned char tmp[4096];
  long done = 0;
  if (!d) {
    errno = EBADF;
    return -1;
  }
  if (!d->text)
    return fwrite(buf, 1, (size_t)n, d->f) == (size_t)n ? n : -1;
  while (done < n) {
    size_t k = (size_t)(n - done) < sizeof tmp ? (size_t)(n - done) : sizeof tmp;
    for (size_t i = 0; i < k; i++)
      tmp[i] = d->cs->a2e[p[done + i]];
    if (fwrite(tmp, 1, k, d->f) != k)
      return -1;
    done += (long)k;
  }
  /* Standardausgabe im Batch: sofort weitergeben (wie ein Deskriptor) */
  if (d >= stdtab && d < stdtab + 3)
    fflush(d->f);
  return n;
}

int FPC_ZOS_DSN_CLOSE(int h)
{
  struct dsn *d = get(h);
  int rc;
  if (!d) {
    errno = EBADF;
    return -1;
  }
  rc = fclose(d->f);
  d->f = 0;
  return rc;
}

/* whence: 0 Anfang, 1 aktuell, 2 Ende; Ergebnis: neue Position oder -1 */
long long FPC_ZOS_DSN_SEEK(int h, long long pos, int whence)
{
  struct dsn *d = get(h);
  if (!d) {
    errno = EBADF;
    return -1;
  }
  if (fseek(d->f, (long)pos, whence) != 0)
    return -1;
  return ftell(d->f);
}

long long FPC_ZOS_DSN_TELL(int h)
{
  struct dsn *d = get(h);
  if (!d) {
    errno = EBADF;
    return -1;
  }
  return ftell(d->f);
}

/* Größe: Ende suchen und zurück; bei Textdateien nicht bestimmbar (-1) */
long long FPC_ZOS_DSN_SIZE(int h)
{
  struct dsn *d = get(h);
  long cur, end;
  if (!d) {
    errno = EBADF;
    return -1;
  }
  cur = ftell(d->f);
  if (cur < 0 || fseek(d->f, 0, SEEK_END) != 0)
    return -1;
  end = ftell(d->f);
  fseek(d->f, cur, SEEK_SET);
  return end;
}

int FPC_ZOS_DSN_ERASE(const char *name)
{
  return remove(name);
}

int FPC_ZOS_DSN_RENAME(const char *from, const char *to)
{
  return rename(from, to);
}

/* Ist die DD-Anweisung dd (ASCII, ohne "DD:") im Job-Schritt vorhanden?
 * fopen("DD:NAME") gelingt unter POSIX(ON) auch ohne DD (LE legt dann einen
 * Stream auf eine z/OS-UNIX-Datei an), deshalb die TIOT des Tasks durchsuchen:
 * PSATOLD (PSA+X'21C') -> TCB, TCBTIO (TCB+X'0C') -> TIOT; Einträge ab
 * TIOT+24: Länge (1 Byte), DD-Name EBCDIC ab +4, Ende bei Länge 0. */
int FPC_ZOS_DD_EXISTS(const char *dd)
{
  unsigned char name[8];
  const unsigned char *p;
  uint32_t tcb, tiot;
  int i;
  memset(name, 0x40, sizeof name);
  for (i = 0; i < 8 && dd[i]; i++) {
    unsigned char c = (unsigned char)dd[i];
    if (c >= 'a' && c <= 'z')
      c -= 'a' - 'A';
    name[i] = a2e_1047[c];
  }
  tcb = *(volatile uint32_t *)(uintptr_t)0x21C;
  if (!tcb)
    return 0;
  tiot = *(volatile uint32_t *)(uintptr_t)(tcb + 0x0C);
  if (!tiot)
    return 0;
  for (p = (const unsigned char *)(uintptr_t)tiot + 24; p[0]; p += p[0])
    if (memcmp(p + 4, name, 8) == 0)
      return 1;
  return 0;
}

/* Umwandlung EBCDIC <-> ISO-8859-1 an Ort und Stelle (Unit zosebcdic) mit der
 * Standard-CCSID, dieselben Tabellen wie für Textdateien (X'15' <-> LF) */
void FPC_ZOS_E2A(unsigned char *p, long n)
{
  const struct zos_ccsid *c = default_ccsid();
  for (long i = 0; i < n; i++)
    p[i] = c->e2a[p[i]];
}

void FPC_ZOS_A2E(unsigned char *p, long n)
{
  const struct zos_ccsid *c = default_ccsid();
  for (long i = 0; i < n; i++)
    p[i] = c->a2e[p[i]];
}

/* dasselbe mit einer bestimmten CCSID; 0 = umgewandelt, -1 = unbekannt (EINVAL) */
int FPC_ZOS_E2A_CCSID(unsigned char *p, long n, int ccsid)
{
  const struct zos_ccsid *c = find_ccsid(ccsid);
  if (!c) {
    errno = EINVAL;
    return -1;
  }
  for (long i = 0; i < n; i++)
    p[i] = c->e2a[p[i]];
  return 0;
}

int FPC_ZOS_A2E_CCSID(unsigned char *p, long n, int ccsid)
{
  const struct zos_ccsid *c = find_ccsid(ccsid);
  if (!c) {
    errno = EINVAL;
    return -1;
  }
  for (long i = 0; i < n; i++)
    p[i] = c->a2e[p[i]];
  return 0;
}

/* Standard-CCSID setzen (gilt für danach geöffnete Datasets und FPC_ZOS_E2A/A2E);
 * 0 = gesetzt, -1 = unbekannt */
int FPC_ZOS_CCSID_SET_DEFAULT(int ccsid)
{
  const struct zos_ccsid *c = find_ccsid(ccsid);
  if (!c) {
    errno = EINVAL;
    return -1;
  }
  defcs = c;
  return 0;
}

int FPC_ZOS_CCSID_DEFAULT(void)
{
  return default_ccsid()->ccsid;
}

int FPC_ZOS_CCSID_SUPPORTED(int ccsid)
{
  return find_ccsid(ccsid) != 0;
}

/* CCSID einer offenen Textdatei ändern (direkt nach Reset/Rewrite, vor der ersten
 * Ein-/Ausgabe); 0 = gesetzt, -1 = kein Dataset-Handle oder unbekannte CCSID */
int FPC_ZOS_DSN_SET_CCSID(int h, int ccsid)
{
  struct dsn *d = get(h);
  const struct zos_ccsid *c = find_ccsid(ccsid);
  if (!d) {
    errno = EBADF;
    return -1;
  }
  if (!c) {
    errno = EINVAL;
    return -1;
  }
  d->cs = c;
  return 0;
}

/* CCSID einer offenen Datei, -1 = kein Dataset-Handle */
int FPC_ZOS_DSN_GET_CCSID(int h)
{
  struct dsn *d = get(h);
  if (!d) {
    errno = EBADF;
    return -1;
  }
  return d->cs ? d->cs->ccsid : default_ccsid()->ccsid;
}

/* Satz-Schnittstelle (Unit zosrecio): Datasets satzweise (type=record), auch VSAM
 * (KSDS, ESDS, RRDS) mit Positionieren über Schlüssel, Ändern und Löschen.
 * Der Inhalt wird nicht umgewandelt. Handles wie bei den Datei-Routinen.
 * mode: fopen-Modus ohne type=record, z. B. "rb", "rb+", "wb", "ab". */
int FPC_ZOS_REC_OPEN(const char *name, const char *mode)
{
  char m[400], fname[1100], attrs[260], v[16];
  const char *comma = 0;
  size_t len;
  int i;
  for (i = 0; i < DSN_MAX; i++)
    if (!tab[i].f)
      break;
  if (i == DSN_MAX) {
    errno = EMFILE;
    return -1;
  }
  /* Attribute nach dem Namen (außerhalb von Hochkommas), wie FPC_ZOS_DSN_OPEN */
  for (const char *q = name, *quote = 0; *q; q++) {
    if (*q == '\'')
      quote = quote ? 0 : q;
    else if (*q == ',' && !quote) {
      comma = q;
      break;
    }
  }
  len = comma ? (size_t)(comma - name) : strlen(name);
  if (len >= sizeof fname || (comma && strlen(comma + 1) >= sizeof attrs)) {
    errno = ENAMETOOLONG;
    return -1;
  }
  memcpy(fname, name, len);
  fname[len] = 0;
  attrs[0] = 0;
  if (comma) {
    strcpy(attrs, comma + 1);
    if (attr_value(attrs, "dsntype", v, sizeof v)) {
      if (mode[0] != 'r')
        alloc_library(fname, attrs, strcasecmp(v, "library") == 0 ? __DSNT_LIBRARY : __DSNT_PDS);
      attr_remove(attrs, "dsntype");
    }
  }
  /* neu schreiben ohne Attribute: vorhandene Attribute behalten */
  snprintf(m, sizeof m, "%s,type=record%s%s", mode,
           attrs[0] ? "," : (mode[0] == 'w') ? ",recfm=*" : "", attrs);
  tab[i].f = fopen(fname, m);
  if (!tab[i].f)
    return -1;
  tab[i].text = 0;
  tab[i].cs = 0;
  return DSN_FIRST + i;
}

/* nächster Satz; Ergebnis: Länge, -1 Ende (errno 0) oder Fehler (errno) */
long FPC_ZOS_REC_READ(int h, void *buf, long max)
{
  struct dsn *d = get(h);
  size_t n;
  if (!d) {
    errno = EBADF;
    return -1;
  }
  errno = 0;
  n = fread(buf, 1, (size_t)max, d->f);
  if (n == 0 && (feof(d->f) || ferror(d->f))) {
    if (feof(d->f))
      errno = 0;
    return -1;
  }
  return (long)n;
}

/* einen Satz schreiben (VSAM KSDS: einfügen, Reihenfolge über den Schlüssel) */
long FPC_ZOS_REC_WRITE(int h, const void *buf, long n)
{
  struct dsn *d = get(h);
  if (!d) {
    errno = EBADF;
    return -1;
  }
  return fwrite(buf, 1, (size_t)n, d->f) == (size_t)n ? n : -1;
}

/* positionieren: how = __KEY_EQ (3), __KEY_GE (5), __KEY_FIRST (1),
 * __KEY_LAST (2), __RBA_EQ (0) ...; 0 = gefunden */
int FPC_ZOS_REC_LOCATE(int h, const void *key, long keylen, int how)
{
  struct dsn *d = get(h);
  if (!d) {
    errno = EBADF;
    return -1;
  }
  return flocate(d->f, key, (size_t)keylen, how);
}

/* zuletzt gelesenen Satz ersetzen (VSAM) */
long FPC_ZOS_REC_UPDATE(int h, const void *buf, long n)
{
  struct dsn *d = get(h);
  if (!d) {
    errno = EBADF;
    return -1;
  }
  return fupdate(buf, (size_t)n, d->f) == (size_t)n ? n : -1;
}

/* zuletzt gelesenen Satz löschen (VSAM KSDS/RRDS) */
int FPC_ZOS_REC_DELETE(int h)
{
  struct dsn *d = get(h);
  if (!d) {
    errno = EBADF;
    return -1;
  }
  return fdelrec(d->f);
}

/* Satzformat: recfm (1 F, 2 V, 3 U, 4 VSAM), maximale Satzlänge,
 * VSAM-Typ (1 ESDS, 2 KSDS, 3 RRDS), Schlüssellänge und -position */
int FPC_ZOS_REC_INFO(int h, int *recfm, long *lrecl, int *vsamtype, int *keylen, int *keypos)
{
  struct dsn *d = get(h);
  fldata_t fl;
  if (!d) {
    errno = EBADF;
    return -1;
  }
  if (fldata(d->f, 0, &fl) != 0)
    return -1;
  *recfm = fl.__dsorgVSAM ? 4 : fl.__recfmF ? 1 : fl.__recfmV ? 2 : 3;
  *lrecl = (long)fl.__maxreclen;
  *vsamtype = fl.__dsorgVSAM ? fl.__vsamtype : 0;
  *keylen = fl.__dsorgVSAM ? (int)fl.__vsamkeylen : 0;
  *keypos = fl.__dsorgVSAM ? (int)fl.__vsamRKP : 0;
  return 0;
}

/* errno der C-Laufzeit (Unit zosrecio: RecLastError) */
int FPC_ZOS_ERRNO(void)
{
  return errno;
}

/* gibt es das Dataset / Member / die DD-Anweisung? (SysUtils.FileExists) */
int FPC_ZOS_DSN_EXISTS(const char *name)
{
  FILE *f = fopen(name, "rb");
  if (!f)
    return 0;
  fclose(f);
  return 1;
}
