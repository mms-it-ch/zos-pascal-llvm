/* PF4: Ausgabewege im Batch (JCL, POSIX(ON)): C-Stream vs. Dateideskriptor.
 * Mit der Korrektur aus runtime/zoscompat.c (DD auf 0/1/2 legen). */
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
void FPC_ZOS_BATCH_STDIO(void);
int main(void)
{
  char b[128];
  int f1 = fcntl(1, F_GETFD), f2 = fcntl(2, F_GETFD), f0 = fcntl(0, F_GETFD);
  FPC_ZOS_BATCH_STDIO();
  snprintf(b, sizeof b, "write(1): vorher fd0 %d fd1 %d fd2 %d, nachher %d %d %d\n", f0, f1, f2,
           fcntl(0, F_GETFD), fcntl(1, F_GETFD), fcntl(2, F_GETFD));
  write(1, b, strlen(b));
  write(2, "write(2): fd 2\n", 15);
  printf("printf: stdout\n");
  fflush(stdout);
  write(1, "write(1): nach printf\n", 22);
  fprintf(stderr, "fprintf: stderr\n");
  return 7;
}
