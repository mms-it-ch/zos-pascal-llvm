/* zoscompat.c - POSIX-Funktionen, die die RTL deklariert, die C-Laufzeit von
 * z/OS aber nicht anbietet. Sie melden einen Fehler (errno), statt beim Binden
 * als unaufgelöst aufzufallen. Wird mit {$L zoscompat.o} in die System-Unit
 * eingebunden.
 */
#include <errno.h>
#include <signal.h>
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
