/* zoscompat.c - POSIX-Funktionen, die die RTL deklariert, die C-Laufzeit von
 * z/OS aber nicht anbietet. Sie melden einen Fehler (errno), statt beim Binden
 * als unaufgelöst aufzufallen. Wird mit {$L zoscompat.o} in die System-Unit
 * eingebunden.
 */
#define _EXT 1   /* fldata */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>
#include <sys/time.h>

/* Die Systemzeit kann ein Anwendungsprogramm unter z/OS nicht setzen. */
int settimeofday(const struct timeval *tv, const void *tz)
{
  (void)tv;
  (void)tz;
  errno = EPERM;
  return -1;
}

/* struct sigaction hat auf z/OS getrennte Felder sa_handler (Offset 0) und
 * sa_sigaction (Offset 24), keine Union. Die RTL setzt wie auf anderen Unixen
 * sa_handler auch zusammen mit SA_SIGINFO; LE nimmt dann aber sa_sigaction.
 * FpSigAction ruft deshalb diese Hülle auf. */
int FPC_ZOS_SIGACTION(int sig, const struct sigaction *act, struct sigaction *oact)
{
  struct sigaction a;
  int rc;
  if (act) {
    a = *act;
    if (a.sa_flags & SA_SIGINFO)
      a.sa_sigaction = (void (*)(int, siginfo_t *, void *))a.sa_handler;
  }
  rc = sigaction(sig, act ? &a : 0, oact);
  if (rc == 0 && oact && (oact->sa_flags & SA_SIGINFO))
    oact->sa_handler = (void (*)(int))oact->sa_sigaction;
  return rc;
}

/* Umgebung für die RTL (envp). LE ruft main nur mit argc und argv auf; ein
 * dritter Parameter enthält einen zufälligen Registerwert. environ ist im
 * ASCII-Modus *__EnvnA() (stdlib.h), die ASCII-Kopie der Umgebung. */
char **FPC_ZOS_ENVIRON(void)
{
  return environ;
}

/* Batch (JCL, POSIX(ON)): LE öffnet die Dateideskriptoren 0, 1 und 2 nicht, nur die
 * C-Streams gehen an die DD-Anweisungen. Die RTL schreibt aber über Deskriptoren.
 * Ist ein Deskriptor geschlossen, wird die DD-Anweisung über die C-Bibliothek
 * geöffnet (Eingabe: STDIN, sonst SYSIN; Ausgabe: STDOUT, sonst SYSPRINT;
 * Fehler: STDERR):
 *  - z/OS-UNIX-Datei (DD PATH=...): der Stream hat einen echten Deskriptor, er
 *    wird auf 0/1/2 gelegt (Inhalt ASCII);
 *  - sonst (SYSOUT=*, Dataset, DD *): die Dataset-Schicht übernimmt das Handle
 *    (zosdsn.c, Umwandlung ASCII <-> EBCDIC). Entscheidend ist fldata
 *    (__dsorgHFS), nicht fileno: für DD:SYSPRINT liefert fileno einen
 *    Deskriptor, obwohl der Stream auf ein Dataset zeigt. */
void FPC_ZOS_DSN_ADOPT(int fd, FILE *f);   /* zosdsn.c */
int FPC_ZOS_DD_EXISTS(const char *dd);      /* zosdsn.c */

void FPC_ZOS_BATCH_STDIO(void)
{
  static const struct { int fd; const char *dd[2]; const char *mode; } map[] = {
    { 0, { "DD:STDIN", "DD:SYSIN" }, "r" },
    { 1, { "DD:STDOUT", "DD:SYSPRINT" }, "a" },
    { 2, { "DD:STDERR", 0 }, "a" } };
  int i, k;
  /* Diagnose (ZOS_DSN_DEBUG, im Batch über CEEOPTS ENVAR): erst am Ende nach
   * stderr, sonst belegt das Öffnen von stderr einen der Deskriptoren */
  char dbg[600];
  int dl = 0;
  dbg[0] = 0;
  for (i = 0; i < 3; i++) {
    FILE *f = 0;
    fldata_t fl;
    int fd;
    if (fcntl(map[i].fd, F_GETFD) != -1 || errno != EBADF)
      continue;
    for (k = 0; k < 2 && !f && map[i].dd[k]; k++) {
      /* nur vorhandene DD-Anweisungen: fopen("DD:X") gelingt sonst trotzdem */
      if (!FPC_ZOS_DD_EXISTS(map[i].dd[k] + 3))
        continue;
      f = fopen(map[i].dd[k], map[i].mode);
      /* SYSOUT=* u. a. lassen sich nicht zum Anhängen öffnen */
      if (!f && map[i].mode[0] == 'a')
        f = fopen(map[i].dd[k], "w");
    }
    if (!f) {
      if (dl < (int)sizeof dbg - 80)
        dl += snprintf(dbg + dl, sizeof dbg - dl, "fd %d: keine DD (errno %d)\n", map[i].fd, errno);
      continue;
    }
    fd = fileno(f);
    if (fd >= 0 && fldata(f, 0, &fl) == 0 && fl.__dsorgHFS) {
      if (fd != map[i].fd)
        dup2(fd, map[i].fd);   /* der Stream bleibt offen */
      if (dl < (int)sizeof dbg - 80)
        dl += snprintf(dbg + dl, sizeof dbg - dl, "fd %d: %s, z/OS-UNIX-Datei, Deskriptor %d\n",
                       map[i].fd, map[i].dd[k - 1], fd);
    } else {
      FPC_ZOS_DSN_ADOPT(map[i].fd, f);
      if (dl < (int)sizeof dbg - 80)
        dl += snprintf(dbg + dl, sizeof dbg - dl, "fd %d: %s, Dataset-Schicht (fileno %d)\n",
                       map[i].fd, map[i].dd[k - 1], fd);
    }
  }
  if (getenv("ZOS_DSN_DEBUG"))
    fprintf(stderr, "FPC_ZOS_BATCH_STDIO:\n%s", dbg);
}
