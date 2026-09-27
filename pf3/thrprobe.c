/* Größen der pthread-Typen mit _UNIX03_THREADS (POSIX-API) */
#include <pthread.h>
#include <stdio.h>
#include <stddef.h>
#define S(t) printf("%-22s %3d  Ausrichtung %d\n", #t, (int)sizeof(t), (int)_Alignof(t))
int main(void)
{
  S(pthread_t); S(pthread_attr_t); S(pthread_mutex_t); S(pthread_mutexattr_t);
  S(pthread_cond_t); S(pthread_condattr_t); S(pthread_key_t); S(pthread_once_t);
  S(pthread_rwlock_t); S(pthread_rwlockattr_t);
  printf("PTHREAD_MUTEX_RECURSIVE %d PTHREAD_CREATE_JOINABLE %d PTHREAD_CREATE_DETACHED %d\n",
         PTHREAD_MUTEX_RECURSIVE, PTHREAD_CREATE_JOINABLE, PTHREAD_CREATE_DETACHED);
  printf("PTHREAD_MUTEX_NORMAL %d PTHREAD_MUTEX_ERRORCHECK %d PTHREAD_MUTEX_DEFAULT %d\n",
         PTHREAD_MUTEX_NORMAL, PTHREAD_MUTEX_ERRORCHECK, PTHREAD_MUTEX_DEFAULT);
  printf("PTHREAD_ONCE_INIT %d\n", (int)PTHREAD_ONCE_INIT);
  {
    pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;
    const unsigned char *p = (const unsigned char *)&m; int i;
    printf("PTHREAD_MUTEX_INITIALIZER:");
    for (i = 0; i < (int)sizeof m; i++) printf(" %02x", p[i]);
    printf("\n");
  }
  return 0;
}
