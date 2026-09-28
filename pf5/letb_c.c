/* PF5: Probe __le_traceback (LE-Traceback-Dienst) für XPLINK-64:
 * welche DSA (R4 oder R4 + 2048), wie endet die Kette (Hauptprogramm, Thread). */
#include <__le_api.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>

static void walk(const char *what)
{
  __tf_parms_t tf;
  _FEEDBACK fc;
  char en[128];
  void *r4;
  __asm__ volatile(" lgr %0,4" : "=r"(r4));
  printf("== %s: R4=%p\n", what, r4);
  memset(&tf, 0, sizeof tf);
  tf.__tf_dsa_addr = r4;
  tf.__tf_call_instruction = (void *)walk;   /* in dieser Funktion */
  for (int i = 0; i < 20; i++) {
    tf.__tf_entry_name.__tf_bufflen = sizeof en;
    tf.__tf_entry_name.__tf_buff = en;
    en[0] = 0;
    __le_traceback(__TRACEBACK_FIELDS, &tf, &fc);
    printf("  sev=%d msg=%d dsa=%p call=%p entry=%p name=%.60s main=%d -> caller dsa=%p call=%p\n",
           fc.tok_sev, fc.tok_msgno, tf.__tf_dsa_addr, tf.__tf_call_instruction,
           tf.__tf_entry_addr, en, tf.__tf_is_main, tf.__tf_caller_dsa_addr,
           tf.__tf_caller_call_instruction);
    if (fc.tok_sev != 0 || !tf.__tf_caller_dsa_addr)
      break;
    void *d = tf.__tf_caller_dsa_addr, *c = tf.__tf_caller_call_instruction;
    memset(&tf, 0, sizeof tf);
    tf.__tf_dsa_addr = d;
    tf.__tf_call_instruction = c;
  }
}

__attribute__((noinline)) static void lvl2(const char *w) { walk(w); }
__attribute__((noinline)) static void lvl1(const char *w) { lvl2(w); }
static void *thr(void *p) { lvl1("Thread"); return p; }

int main(void)
{
  pthread_t t;
  lvl1("Hauptprogramm");
  pthread_create(&t, 0, thr, 0);
  pthread_join(t, 0);
  return 0;
}
