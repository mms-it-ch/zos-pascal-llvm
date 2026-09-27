/* zosatomic.c - atomare Grundoperationen für die FPC-RTL auf z/OS (s390x).
 *
 * Der s390x-Port von FPC hat keinen eigenen Codegenerator und damit keine
 * Assembler-Routinen; die RTL ruft diese Funktionen auf. clang erzeugt für
 * die __atomic-Builtins CS/CSG (compare and swap).
 *
 * Die Namen FPC_ATOMIC_CMP_XCHG_32/64 benutzt außerdem die generische
 * Sperre der RTL (rtl/inc/generic.inc, AtomicEnterLock).
 */
#include <stdint.h>

int32_t FPC_ATOMIC_CMP_XCHG_32(int32_t *target, int32_t newvalue, int32_t comparand)
{
  __atomic_compare_exchange_n(target, &comparand, newvalue, 0,
                              __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
  return comparand;
}

int64_t FPC_ATOMIC_CMP_XCHG_64(int64_t *target, int64_t newvalue, int64_t comparand)
{
  __atomic_compare_exchange_n(target, &comparand, newvalue, 0,
                              __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
  return comparand;
}

void FPC_MEMORY_BARRIER(void)
{
  __atomic_thread_fence(__ATOMIC_SEQ_CST);
}
