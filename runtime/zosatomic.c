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

/* Direkte atomare Operationen statt der generischen Compare-and-swap-Schleifen
 * der RTL (dort je Versuch ein Aufruf): inc/dec liefern den neuen Wert,
 * add/sub/xchg den alten (wie fpc_atomic_* in rtl/inc/generic.inc). */
#define FPC_ATOMIC_OPS(bits, type)                                              \
  type FPC_ATOMIC_INC_##bits(type *t) { return __atomic_add_fetch(t, 1, __ATOMIC_SEQ_CST); } \
  type FPC_ATOMIC_DEC_##bits(type *t) { return __atomic_sub_fetch(t, 1, __ATOMIC_SEQ_CST); } \
  type FPC_ATOMIC_ADD_##bits(type *t, type v) { return __atomic_fetch_add(t, v, __ATOMIC_SEQ_CST); } \
  type FPC_ATOMIC_SUB_##bits(type *t, type v) { return __atomic_fetch_sub(t, v, __ATOMIC_SEQ_CST); } \
  type FPC_ATOMIC_XCHG_##bits(type *t, type v) { return __atomic_exchange_n(t, v, __ATOMIC_SEQ_CST); }

FPC_ATOMIC_OPS(32, int32_t)
FPC_ATOMIC_OPS(64, int64_t)
