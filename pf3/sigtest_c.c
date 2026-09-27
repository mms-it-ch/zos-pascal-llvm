/* Gegenprobe in C: kommt SIGFPE bei einer IEEE-Falle beim Handler an? */
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void handler(int sig, siginfo_t *info, void *ctx)
{
  (void)ctx;
  printf("Handler: Signal %d si_code %d\n", sig, info->si_code);
  fflush(stdout);
  _exit(sig);
}

static unsigned get_fpc(void) { unsigned v; __asm__ volatile(" efpc %0" : "=d"(v)); return v; }
static void set_fpc(unsigned v) { __asm__ volatile(" sfpc %0" : : "d"(v)); }

int main(int argc, char **argv)
{
  struct sigaction act;
  volatile double a = 1.0, b = 0.0;
  (void)argv;
  memset(&act, 0, sizeof act);
  act.sa_sigaction = handler;
  act.sa_flags = SA_SIGINFO;
  printf("sigaction = %d\n", sigaction(SIGFPE, &act, NULL));
  printf("FPC vorher %08x\n", get_fpc());
  if (argc > 1)
    set_fpc((get_fpc() & 0x07ffffff) | 0xe0000000);
  printf("FPC nachher %08x\n", get_fpc());
  fflush(stdout);
  printf("%f\n", a / b);
  return 0;
}
