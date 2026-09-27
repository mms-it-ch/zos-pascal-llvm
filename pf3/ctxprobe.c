/* Layout von mcontext_t (85 long, undokumentiert) im SIGFPE-Handler bestimmen:
 * Register mit Markern laden, IEEE-Falle auslösen, Kontext ausgeben. */
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <ucontext.h>

static void handler(int sig, siginfo_t *info, void *ctx)
{
  ucontext_t *uc = ctx;
  unsigned long *m = (unsigned long *)&uc->uc_mcontext;
  int i;
  printf("sig %d code %d addr %p sizeof(mcontext) %d\n", sig, info->si_code,
         info->si_addr, (int)sizeof(uc->uc_mcontext));
  for (i = 0; i < 85; i++)
    printf("%3d +%03x %016lx\n", i, i * 8, m[i]);
  fflush(stdout);
  _exit(3);
}

int main(void)
{
  struct sigaction act;
  memset(&act, 0, sizeof act);
  act.sa_sigaction = handler;
  act.sa_flags = SA_SIGINFO;
  sigaction(SIGFPE, &act, NULL);
  __asm__ volatile(
    " larl 1,*\n"
    " stg 1,0(%0)\n"
    : : "a"(&act) : "1", "memory");
  printf("larl-Adresse %016lx\n", *(unsigned long *)&act);
  fflush(stdout);
  __asm__ volatile(
    " efpc 1\n"
    " oilh 1,57344\n"
    " sfpc 1\n"
    " lghi 0,4096\n"
    " cdgbr 0,0\n"
    " lzdr 2\n"
    " iihf 6,286331153\n"
    " iilf 6,1717986918\n"
    " iihf 8,572662306\n"
    " iilf 8,2290649224\n"
    " iihf 9,858993459\n"
    " iilf 9,2576980377\n"
    " iihf 10,1145324612\n"
    " iilf 10,2863311530\n"
    " larl 11,*\n"
    " ddbr 0,2\n"
    : : : "0", "1", "6", "8", "9", "10", "11", "f0", "f2", "memory");
  return 0;
}
