/* zosc31.c - Aufruf von AMODE-31-Programmen (COBOL, PL/I, Assembler, OS-Linkage) aus
 * Pascal (AMODE 64) über einen Brückenprozess (Unit zoscall31).
 *
 * Ein AMODE-64-Programm kann ein AMODE-31-Programm nicht direkt aufrufen. Ohne die
 * LE-Schnittstelle CEL4RO31 (z/OS 3.1+, pf8/README.md) geht der Aufruf hier über einen
 * eigenen Prozess: die Brücke pf8/zpcall31.s (HLASM, AMODE 31, ohne LE) liest Aufträge
 * über eine Pipe, lädt das Programm (LOAD), legt die Datenbereiche in ihren eigenen
 * Speicher (unter 2 GB), baut die OS-Parameterliste (R1, Hochbit am letzten Eintrag),
 * ruft es mit BASSM auf und schickt R15 und die geänderten Bereiche zurück. Eine Sitzung
 * (ein Brückenprozess) bedient beliebig viele Aufrufe.
 *
 * Protokoll (Ganzzahlen 4 Byte Big-Endian, wie auf z/OS):
 *   Auftrag:  X'E9F3F1C3' ("Z31C" EBCDIC), Programmname 8 Byte EBCDIC (mit Leerzeichen
 *             aufgefüllt), Anzahl n, je Bereich: Länge, Daten
 *   Antwort:  X'E9F3F1D9' ("Z31R"), Status (0 ok, 1 LOAD gescheitert, 2 Auftrag
 *             ungültig, 3 Speicher), R15 bzw. Abend-/Grundcode, je Bereich: Länge, Daten
 *   Ende:     X'E9F3F1C5' ("Z31E")
 * Grenzen: höchstens C31_MAXAREAS Bereiche, je Bereich höchstens C31_MAXLEN Byte.
 *
 * Portabel (POSIX): auf x86_64 mit einer Attrappe der Brücke getestet
 * (tests/c/fake_zpcall31.c). */
#include <errno.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define C31_MAXSESS 16
#define C31_MAXAREAS 32
#define C31_MAXLEN (16L * 1024 * 1024)

#define MAGIC_CALL 0xE9F3F1C3u
#define MAGIC_RESP 0xE9F3F1D9u
#define MAGIC_END  0xE9F3F1C5u

/* runtime/zosdsn.c: ISO-8859-1 -> EBCDIC */
int FPC_ZOS_A2E_CCSID(unsigned char *p, long n, int ccsid);

struct sess {
  pid_t pid;
  int to, from;   /* Pipe zur Brücke, von der Brücke */
};
static struct sess sessions[C31_MAXSESS];

static int writeall(int fd, const void *buf, size_t n)
{
  const char *p = buf;
  while (n > 0) {
    ssize_t k = write(fd, p, n);
    if (k < 0) {
      if (errno == EINTR)
        continue;
      return -1;
    }
    p += k;
    n -= (size_t)k;
  }
  return 0;
}

static int readall(int fd, void *buf, size_t n)
{
  char *p = buf;
  while (n > 0) {
    ssize_t k = read(fd, p, n);
    if (k < 0) {
      if (errno == EINTR)
        continue;
      return -1;
    }
    if (k == 0) {
      errno = EPIPE;
      return -1;
    }
    p += k;
    n -= (size_t)k;
  }
  return 0;
}

static int put32(int fd, unsigned long v)
{
  unsigned char b[4] = { (unsigned char)(v >> 24), (unsigned char)(v >> 16),
                         (unsigned char)(v >> 8), (unsigned char)v };
  return writeall(fd, b, 4);
}

static int get32(int fd, unsigned long *v)
{
  unsigned char b[4];
  if (readall(fd, b, 4))
    return -1;
  *v = ((unsigned long)b[0] << 24) | ((unsigned long)b[1] << 16) |
       ((unsigned long)b[2] << 8) | b[3];
  return 0;
}

/* Brücke starten; bridge = Pfad des Programms. Ergebnis: Sitzung >= 0 oder -1 (errno) */
int FPC_ZOS_C31_OPEN(const char *bridge)
{
  int i, to[2], from[2];
  pid_t pid;
  for (i = 0; i < C31_MAXSESS; i++)
    if (!sessions[i].pid)
      break;
  if (i == C31_MAXSESS) {
    errno = EMFILE;
    return -1;
  }
  if (pipe(to))
    return -1;
  if (pipe(from)) {
    close(to[0]);
    close(to[1]);
    return -1;
  }
  pid = fork();
  if (pid < 0) {
    close(to[0]); close(to[1]); close(from[0]); close(from[1]);
    return -1;
  }
  if (pid == 0) {
    dup2(to[0], 0);
    dup2(from[1], 1);
    close(to[0]); close(to[1]); close(from[0]); close(from[1]);
    execl(bridge, bridge, (char *)0);
    _exit(127);
  }
  close(to[0]);
  close(from[1]);
  /* SIGPIPE nicht tödlich, wenn die Brücke stirbt: write liefert dann EPIPE */
  signal(SIGPIPE, SIG_IGN);
  sessions[i].pid = pid;
  sessions[i].to = to[1];
  sessions[i].from = from[0];
  return i;
}

/* Programm module (ASCII, bis 8 Zeichen) mit n Bereichen aufrufen. Die Bereiche werden
 * hin und zurück kopiert. *rc: R15 des Programms (Status 0) bzw. Code (Status 1).
 * Ergebnis: Status der Brücke (0..3) oder -1 (Übertragung, errno). */
int FPC_ZOS_C31_CALL(int s, const char *module, int n, void *const *areas,
                     const long *lens, int *rc)
{
  struct sess *ss;
  unsigned char name[8];
  unsigned long v, status, r15;
  int i;
  size_t k;
  if (s < 0 || s >= C31_MAXSESS || !sessions[s].pid) {
    errno = EBADF;
    return -1;
  }
  if (n < 0 || n > C31_MAXAREAS) {
    errno = EINVAL;
    return -1;
  }
  for (i = 0; i < n; i++)
    if (lens[i] < 0 || lens[i] > C31_MAXLEN) {
      errno = EINVAL;
      return -1;
    }
  ss = &sessions[s];
  memset(name, ' ', sizeof name);
  for (k = 0; k < sizeof name && module[k]; k++) {
    unsigned char c = (unsigned char)module[k];
    name[k] = (c >= 'a' && c <= 'z') ? (unsigned char)(c - 'a' + 'A') : c;
  }
  if (module[k] && k == sizeof name) {
    errno = ENAMETOOLONG;
    return -1;
  }
  FPC_ZOS_A2E_CCSID(name, sizeof name, 1047);
  if (put32(ss->to, MAGIC_CALL) || writeall(ss->to, name, sizeof name) ||
      put32(ss->to, (unsigned long)n))
    return -1;
  for (i = 0; i < n; i++)
    if (put32(ss->to, (unsigned long)lens[i]) || writeall(ss->to, areas[i], (size_t)lens[i]))
      return -1;
  if (get32(ss->from, &v))
    return -1;
  if (v != MAGIC_RESP) {
    errno = EIO;
    return -1;
  }
  if (get32(ss->from, &status) || get32(ss->from, &r15))
    return -1;
  *rc = (int)(unsigned int)r15;
  if (status != 0)
    return (int)status;
  for (i = 0; i < n; i++) {
    if (get32(ss->from, &v))
      return -1;
    if ((long)v != lens[i]) {
      errno = EIO;
      return -1;
    }
    if (readall(ss->from, areas[i], (size_t)lens[i]))
      return -1;
  }
  return 0;
}

/* Sitzung beenden; Ergebnis: Exit-Status der Brücke oder -1 */
int FPC_ZOS_C31_CLOSE(int s)
{
  struct sess *ss;
  int st = 0;
  if (s < 0 || s >= C31_MAXSESS || !sessions[s].pid) {
    errno = EBADF;
    return -1;
  }
  ss = &sessions[s];
  put32(ss->to, MAGIC_END);
  close(ss->to);
  close(ss->from);
  while (waitpid(ss->pid, &st, 0) < 0 && errno == EINTR)
    ;
  ss->pid = 0;
  return WIFEXITED(st) ? WEXITSTATUS(st) : -1;
}
