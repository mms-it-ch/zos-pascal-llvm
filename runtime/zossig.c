/* zossig.c - Signal in eine Pascal-Ausnahme umleiten.
 *
 * Eine Ausnahme direkt im Signal-Handler auszulösen geht auf z/OS nicht: der
 * Unwinder kommt nicht durch die LE-Frames der Signalzustellung. Wie auf
 * anderen FPC-Zielen wird deshalb der Maschinenkontext geändert: kehrt der
 * Handler zurück, läuft das Programm in fn (Pascal-Routine, XPLINK) weiter,
 * als hätte die unterbrochene Stelle fn aufgerufen:
 *   R1 = err, R2 = Fehleradresse, R3 = Frame (R4), R5/R6 = Deskriptor von fn,
 *   R7 = Fehleradresse - 2 (XPLINK-Rücksprung = R7 + 2), PSW = Einsprung von fn.
 * Die Unterbrechungsadresse zeigt hinter die auslösende Anweisung (IEEE-Falle)
 * oder auf sie; der Personality-Test (ip - 1) trifft so die unterbrochene
 * Funktion.
 *
 * mcontext_t ist in den Headern nur long[85]; Offsets mit pf3/ctxprobe.c
 * gemessen (z/OS 3.1, AMODE 64, XPLINK):
 *   +0x080 GPR 0..15, +0x140 FPR 0..15, +0x1C0 FPC (32 Bit),
 *   +0x228 PSW-Maske, +0x230 PSW-Adresse
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ucontext.h>

#define MC_GPR     0x080
#define MC_FPC     0x1C0
#define MC_PSWADDR 0x230

int FPC_ZOS_FUNC_NAME(uint64_t ip, char *buf, int n);   /* zosunwind.c */

static uint64_t get(const uint8_t *m, int off) { uint64_t v; memcpy(&v, m + off, 8); return v; }
static void put(uint8_t *m, int off, uint64_t v) { memcpy(m + off, &v, 8); }

void FPC_ZOS_SIGREDIRECT(void *ucontext, void *fn, long err)
{
  uint8_t *m = ucontext;           /* uc_mcontext ist das erste Feld */
  const uint64_t *desc = fn;       /* +0 ADA, +8 Einsprung */
  uint64_t pc = get(m, MC_PSWADDR);
  uint64_t orig_r7 = get(m, MC_GPR + 8 * 7);
  uint32_t fpc;

  put(m, MC_GPR + 8 * 1, (uint64_t)err);
  put(m, MC_GPR + 8 * 2, pc);
  put(m, MC_GPR + 8 * 3, get(m, MC_GPR + 8 * 4));
  put(m, MC_GPR + 8 * 5, desc[0]);
  put(m, MC_GPR + 8 * 6, desc[1]);
  put(m, MC_GPR + 8 * 7, pc - 2);
  put(m, MC_PSWADDR, desc[1]);
  /* Ausnahmeflags und DXC löschen, Masken und Rundung behalten */
  memcpy(&fpc, m + MC_FPC, 4);
  fpc &= ~0x00F8FF00u;
  memcpy(m + MC_FPC, &fpc, 4);
  if (getenv("ZOS_UNWIND_DEBUG")) {
    char b[512], f1[160] = "", f2[160] = "";
    int n = snprintf(b, sizeof b, "zossig: err=%ld pc=%llx R7=%llx R4=%llx R5=%llx R6=%llx\n", err,
                     (unsigned long long)pc, (unsigned long long)orig_r7,
                     (unsigned long long)get(m, MC_GPR + 32),
                     (unsigned long long)get(m, MC_GPR + 40), (unsigned long long)get(m, MC_GPR + 48));
    write(2, b, n);
    /* Namen nur für Adressen im Code des Programms (EPM-Suche liest rückwärts) */
    uint64_t self = (uint64_t)((const uint64_t *)(void *)FPC_ZOS_SIGREDIRECT)[1];
    if (pc > 0x1000000 && pc - self + (64u << 20) < (128u << 20))
      FPC_ZOS_FUNC_NAME(pc, f1, sizeof f1);
    if (orig_r7 > 0x1000000 && orig_r7 - self + (64u << 20) < (128u << 20))
      FPC_ZOS_FUNC_NAME(orig_r7 + 2, f2, sizeof f2);
    n = snprintf(b, sizeof b, "zossig: pc in %s, R7 in %s\n", f1, f2);
    write(2, b, n);
  }
  /* Kehrt der Handler normal zurück, beendet LE das Programm bei einer
   * Programmunterbrechung trotzdem (CEE3224S) -> Kontext selbst laden. */
  setcontext((ucontext_t *)ucontext);
}
