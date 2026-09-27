/* zoscompat.c - POSIX-Funktionen, die die RTL deklariert, die C-Laufzeit von
 * z/OS aber nicht anbietet. Sie melden einen Fehler (errno), statt beim Binden
 * als unaufgelöst aufzufallen. Wird mit {$L zoscompat.o} in die System-Unit
 * eingebunden.
 */
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
 * Ist ein Deskriptor geschlossen und die DD STDIN/STDOUT/STDERR vorhanden (z. B. als
 * PATH=...), wird sie über die C-Bibliothek geöffnet und ihr Deskriptor auf 0/1/2
 * gelegt (bei einer z/OS-UNIX-Datei hat der Stream einen echten Deskriptor). */
void FPC_ZOS_BATCH_STDIO(void)
{
  static const struct { int fd; const char *dd; const char *mode; } map[] = {
    { 0, "DD:STDIN", "r" }, { 1, "DD:STDOUT", "a" }, { 2, "DD:STDERR", "a" } };
  int i;
  for (i = 0; i < 3; i++) {
    FILE *f;
    int fd;
    if (fcntl(map[i].fd, F_GETFD) != -1 || errno != EBADF)
      continue;
    f = fopen(map[i].dd, map[i].mode);
    if (!f)
      continue;
    fd = fileno(f);
    if (fd >= 0 && fd != map[i].fd)
      dup2(fd, map[i].fd);   /* der Stream bleibt offen */
  }
}
