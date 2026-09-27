/* zosfpu.c - Zugriff auf das Floating-Point-Control-Register (FPC) für die
 * FPC-RTL auf z/OS (s390x hat im Port keine Assembler-Routinen).
 *
 * FPC (z/Architecture): Bits 0-4 Ausnahmemasken (ungültig, Division durch 0,
 * Überlauf, Unterlauf, ungenau), Bits 8-12 die zugehörigen Flags, Bits 16-23 der
 * Data Exception Code, Bits 29-31 der BFP-Rundungsmodus (0 nächster Wert,
 * 1 gegen 0, 2 gegen +unendlich, 3 gegen -unendlich).
 */
#include <stdint.h>

uint32_t FPC_ZOS_GET_FPC(void)
{
  uint32_t v;
  __asm__ volatile(" efpc %0" : "=d"(v));
  return v;
}

void FPC_ZOS_SET_FPC(uint32_t v)
{
  __asm__ volatile(" sfpc %0" : : "d"(v));
}
