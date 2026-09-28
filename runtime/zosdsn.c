/* zosdsn.c - MVS-Datasets für die Datei-Routinen der RTL (Do_Open, Do_Read, ...).
 *
 * Datasets haben keine Dateideskriptoren (fileno = -1); sie gehen nur über die
 * C-Streams. Die RTL leitet Namen der Form
 *     //'HLQ.NAME'   //'HLQ.PDS(MEMBER)'   //NAME (mit TSO-Präfix)
 *     //DD:DDNAME    DD:DDNAME
 * hierher; ein Zusatz nach einem Komma geht als fopen-Attribut mit, z. B.
 *     //'HLQ.NEU',recfm=fb,lrecl=80,space=(trk,(5,5))
 * Die Handles sind eigene Nummern ab DSN_FIRST (keine Dateideskriptoren).
 *
 * Textdateien: Textmodus der C-Laufzeit (ein Satz = eine Zeile; FB wird beim
 * Schreiben mit Leerzeichen aufgefüllt und beim Lesen gekürzt, VB behält die
 * Länge), dazu Umwandlung ISO-8859-1 <-> IBM-1047, Zeilenende LF <-> X'15'
 * (wie iconv unter z/OS UNIX). Binärdateien: Bytestrom ("rb"/"wb"), ohne
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
#include <stdint.h>
#include <strings.h>

#define DSN_FIRST 0x7F000000
#define DSN_MAX 256

struct dsn {
  FILE *f;
  int text;
};

static struct dsn tab[DSN_MAX];
static struct dsn stdtab[3];   /* Batch: Handles 0, 1, 2 */

/* ISO-8859-1 -> IBM-1047 und zurück (erzeugt mit iconv; LF <-> X'15') */
static const unsigned char a2e[256] = {
  0x00, 0x01, 0x02, 0x03, 0x37, 0x2D, 0x2E, 0x2F, 0x16, 0x05, 0x15, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
  0x10, 0x11, 0x12, 0x13, 0x3C, 0x3D, 0x32, 0x26, 0x18, 0x19, 0x3F, 0x27, 0x1C, 0x1D, 0x1E, 0x1F,
  0x40, 0x5A, 0x7F, 0x7B, 0x5B, 0x6C, 0x50, 0x7D, 0x4D, 0x5D, 0x5C, 0x4E, 0x6B, 0x60, 0x4B, 0x61,
  0xF0, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0x7A, 0x5E, 0x4C, 0x7E, 0x6E, 0x6F,
  0x7C, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6,
  0xD7, 0xD8, 0xD9, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xAD, 0xE0, 0xBD, 0x5F, 0x6D,
  0x79, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96,
  0x97, 0x98, 0x99, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xC0, 0x4F, 0xD0, 0xA1, 0x07,
  0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x06, 0x17, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x09, 0x0A, 0x1B,
  0x30, 0x31, 0x1A, 0x33, 0x34, 0x35, 0x36, 0x08, 0x38, 0x39, 0x3A, 0x3B, 0x04, 0x14, 0x3E, 0xFF,
  0x41, 0xAA, 0x4A, 0xB1, 0x9F, 0xB2, 0x6A, 0xB5, 0xBB, 0xB4, 0x9A, 0x8A, 0xB0, 0xCA, 0xAF, 0xBC,
  0x90, 0x8F, 0xEA, 0xFA, 0xBE, 0xA0, 0xB6, 0xB3, 0x9D, 0xDA, 0x9B, 0x8B, 0xB7, 0xB8, 0xB9, 0xAB,
  0x64, 0x65, 0x62, 0x66, 0x63, 0x67, 0x9E, 0x68, 0x74, 0x71, 0x72, 0x73, 0x78, 0x75, 0x76, 0x77,
  0xAC, 0x69, 0xED, 0xEE, 0xEB, 0xEF, 0xEC, 0xBF, 0x80, 0xFD, 0xFE, 0xFB, 0xFC, 0xBA, 0xAE, 0x59,
  0x44, 0x45, 0x42, 0x46, 0x43, 0x47, 0x9C, 0x48, 0x54, 0x51, 0x52, 0x53, 0x58, 0x55, 0x56, 0x57,
  0x8C, 0x49, 0xCD, 0xCE, 0xCB, 0xCF, 0xCC, 0xE1, 0x70, 0xDD, 0xDE, 0xDB, 0xDC, 0x8D, 0x8E, 0xDF,
};
static const unsigned char e2a[256] = {
  0x00, 0x01, 0x02, 0x03, 0x9C, 0x09, 0x86, 0x7F, 0x97, 0x8D, 0x8E, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
  0x10, 0x11, 0x12, 0x13, 0x9D, 0x0A, 0x08, 0x87, 0x18, 0x19, 0x92, 0x8F, 0x1C, 0x1D, 0x1E, 0x1F,
  0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x17, 0x1B, 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x05, 0x06, 0x07,
  0x90, 0x91, 0x16, 0x93, 0x94, 0x95, 0x96, 0x04, 0x98, 0x99, 0x9A, 0x9B, 0x14, 0x15, 0x9E, 0x1A,
  0x20, 0xA0, 0xE2, 0xE4, 0xE0, 0xE1, 0xE3, 0xE5, 0xE7, 0xF1, 0xA2, 0x2E, 0x3C, 0x28, 0x2B, 0x7C,
  0x26, 0xE9, 0xEA, 0xEB, 0xE8, 0xED, 0xEE, 0xEF, 0xEC, 0xDF, 0x21, 0x24, 0x2A, 0x29, 0x3B, 0x5E,
  0x2D, 0x2F, 0xC2, 0xC4, 0xC0, 0xC1, 0xC3, 0xC5, 0xC7, 0xD1, 0xA6, 0x2C, 0x25, 0x5F, 0x3E, 0x3F,
  0xF8, 0xC9, 0xCA, 0xCB, 0xC8, 0xCD, 0xCE, 0xCF, 0xCC, 0x60, 0x3A, 0x23, 0x40, 0x27, 0x3D, 0x22,
  0xD8, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0xAB, 0xBB, 0xF0, 0xFD, 0xFE, 0xB1,
  0xB0, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, 0x70, 0x71, 0x72, 0xAA, 0xBA, 0xE6, 0xB8, 0xC6, 0xA4,
  0xB5, 0x7E, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0xA1, 0xBF, 0xD0, 0x5B, 0xDE, 0xAE,
  0xAC, 0xA3, 0xA5, 0xB7, 0xA9, 0xA7, 0xB6, 0xBC, 0xBD, 0xBE, 0xDD, 0xA8, 0xAF, 0x5D, 0xB4, 0xD7,
  0x7B, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0xAD, 0xF4, 0xF6, 0xF2, 0xF3, 0xF5,
  0x7D, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0xB9, 0xFB, 0xFC, 0xF9, 0xFA, 0xFF,
  0x5C, 0xF7, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0xB2, 0xD4, 0xD6, 0xD2, 0xD3, 0xD5,
  0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0xB3, 0xDB, 0xDC, 0xD9, 0xDA, 0x9F,
};

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

/* mode: 0 lesen, 1 schreiben (neu), 2 lesen/schreiben, 3 anhängen,
 * 4 lesen/schreiben (neu).
 * Ergebnis: Handle oder -1 (errno gesetzt). */
int FPC_ZOS_DSN_OPEN(const char *name, int mode, int text)
{
  static const char *const modes[2][5] = {
    { "rb", "wb", "rb+", "ab", "wb+" },
    { "r", "w", "r+", "a", "w+" } };
  char fname[1100], fmode[300];
  const char *comma;
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
  /* Neu schreiben ohne eigene Attribute: recfm=* behält die Attribute eines
   * vorhandenen Datasets (sonst legt "w" es mit Standardattributen neu an,
   * aus FB 80 würde VB 1024) */
  snprintf(fmode, sizeof fmode, "%s%s%s", modes[text != 0][mode],
           comma ? "," : (mode == 1 || mode == 4) ? ",recfm=*" : "",
           comma ? comma + 1 : "");
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
  return DSN_FIRST + i;
}

/* Standard-Handle fd (0, 1, 2) auf einen offenen Stream legen (Batch) */
void FPC_ZOS_DSN_ADOPT(int fd, FILE *f)
{
  if (fd >= 0 && fd <= 2) {
    stdtab[fd].f = f;
    stdtab[fd].text = 1;
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
      p[i] = e2a[p[i]];
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
      tmp[i] = a2e[p[done + i]];
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
    name[i] = a2e[c];
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

/* Umwandlung IBM-1047 <-> ISO-8859-1 an Ort und Stelle (Unit zosebcdic),
 * dieselben Tabellen wie für Textdateien (X'15' <-> LF) */
void FPC_ZOS_E2A(unsigned char *p, long n)
{
  for (long i = 0; i < n; i++)
    p[i] = e2a[p[i]];
}

void FPC_ZOS_A2E(unsigned char *p, long n)
{
  for (long i = 0; i < n; i++)
    p[i] = a2e[p[i]];
}
