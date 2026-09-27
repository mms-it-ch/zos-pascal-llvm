/* Rückgabe von pthread_cond_timedwait bei Zeitablauf (z/OS, _UNIX03_THREADS) */
#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
int main(void)
{
  pthread_mutex_t m; pthread_cond_t c; struct timeval tv; struct timespec ts; int rc;
  pthread_mutexattr_t a; int rec = 1;
  pthread_mutexattr_init(&a);
  if (rec) pthread_mutexattr_settype(&a, PTHREAD_MUTEX_RECURSIVE);
  pthread_mutex_init(&m, &a); pthread_cond_init(&c, NULL);
  gettimeofday(&tv, NULL);
  ts.tv_sec = tv.tv_sec + 1; ts.tv_nsec = tv.tv_usec * 1000;
  pthread_mutex_lock(&m);
  errno = 0;
  rc = pthread_cond_timedwait(&c, &m, &ts);
  printf("rc=%d errno=%d ETIMEDOUT=%d EAGAIN=%d sizeof(timespec)=%d\n", rc, errno, ETIMEDOUT, EAGAIN, (int)sizeof ts);
  return 0;
}
