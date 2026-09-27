/* zosunwind.c - Unwinder (Itanium-ABI-Schnittstelle _Unwind_*) für z/OS XPLINK-64.
 *
 * Das LLVM-Backend legt auf z/OS für Funktionen mit Landing Pads Personality
 * und LSDA im PPA1 ab (als Displacements in die ADA der Funktion). Frei
 * verfügbare Unwinder (libunwind) können z/OS nicht; dieser Unwinder läuft
 * die XPLINK-Stackframes selbst ab:
 *
 *   Entry Point Marker (16 Byte vor dem Einsprung):
 *     +0  X'00C300C500C500F1'  Eyecatcher
 *     +8  Offset zum PPA1 (4 Byte, relativ zum EPM)
 *     +12 DSA-Größe (Bits 0-26) und Flags (0x08 Blatt, 0x04 alloca)
 *   Prolog: stmg rL,rH,2048+8*(rL-4)-DSA(4) ; aghi 4,-DSA
 *     -> Register rL..rH im eigenen Frame ab R4+2048+8*(r-4); R7 = Rücksprung
 *     -> R4 des Aufrufers = R4 + DSA-Größe
 *   PPA1: +2 Maske der gesicherten GPRs (Bit 15-r), +8..+11 Flags,
 *     optional Argumentbereich, FPR-Maske/-Sicherungsbereich (F8 zuerst,
 *     aufsteigend), VR-Maske, EH-Block (Personality/LSDA als ADA-Displacement),
 *     Name, Offset zum EPM.
 *   Funktionen mit Landing Pads sichern R5 (ihre ADA) immer im Frame.
 *   Landing Pad: R1 = Exception-Objekt, R2 = Selektor.
 *
 * Zwei Phasen wie in der Itanium-ABI: Phase 1 sucht einen Handler, Phase 2
 * ruft die Personality für Aufräumarbeiten auf und springt in den Landing Pad.
 *
 * Diagnose: Umgebungsvariable ZOS_UNWIND_DEBUG=1.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
  _URC_NO_REASON = 0,
  _URC_FOREIGN_EXCEPTION_CAUGHT = 1,
  _URC_FATAL_PHASE2_ERROR = 2,
  _URC_FATAL_PHASE1_ERROR = 3,
  _URC_NORMAL_STOP = 4,
  _URC_END_OF_STACK = 5,
  _URC_HANDLER_FOUND = 6,
  _URC_INSTALL_CONTEXT = 7,
  _URC_CONTINUE_UNWIND = 8
} _Unwind_Reason_Code;

typedef int _Unwind_Action;
#define _UA_SEARCH_PHASE 1
#define _UA_CLEANUP_PHASE 2
#define _UA_HANDLER_FRAME 4

struct _Unwind_Exception;
typedef void (*_Unwind_Exception_Cleanup_Fn)(_Unwind_Reason_Code,
                                             struct _Unwind_Exception *);
struct _Unwind_Exception {
  uint64_t exception_class;
  _Unwind_Exception_Cleanup_Fn exception_cleanup;
  uintptr_t private_1;
  uintptr_t private_2;   /* Phase 2: R4 des Handler-Frames */
};

/* Zustand eines Frames: Registerwerte an der Aufrufstelle. Das Layout von
 * gpr/fpr/ip wird von resume() per Assembler gelesen. */
struct _Unwind_Context {
  uint64_t gpr[16];          /* +0   */
  uint64_t fpr[16];          /* +128 (F8..F15 benutzt) */
  uint64_t ip;               /* +256 Rücksprungadresse bzw. Ziel */
  /* aus EPM/PPA1 */
  uint64_t entry;
  const uint8_t *ppa1;
  uint32_t dsa;
  uint32_t epmflags;
  uint16_t gprmask;
  uint16_t fprmask;
  uint32_t fprloc;
  uint64_t persdisp, lsdadisp;
  int haseh;
};

typedef _Unwind_Reason_Code (*personality_fn)(int, _Unwind_Action, uint64_t,
                                              struct _Unwind_Exception *,
                                              struct _Unwind_Context *);

static int debug = -1;
#define DBG(...) do { if (debug) fprintf(stderr, "zosunwind: " __VA_ARGS__); } while (0)

static const uint8_t eyecatcher[8] = {0x00, 0xC3, 0x00, 0xC5, 0x00, 0xC5, 0x00, 0xF1};

static uint32_t get32(const uint8_t *p) { uint32_t v; memcpy(&v, p, 4); return v; }
static uint16_t get16(const uint8_t *p) { uint16_t v; memcpy(&v, p, 2); return v; }
static uint64_t get64(const uint8_t *p) { uint64_t v; memcpy(&v, p, 8); return v; }

/* PPA1 zum EPM prüfen und die benötigten Felder auslesen. */
static int parse_epm(const uint8_t *epm, uint64_t ip, struct _Unwind_Context *c)
{
  if (memcmp(epm, eyecatcher, 8) != 0)
    return 0;
  int32_t off = (int32_t)get32(epm + 8);
  const uint8_t *ppa1 = epm + off;
  if (ppa1[0] != 0x02 || ppa1[1] != 0xCE)
    return 0;
  uint32_t codelen = get32(ppa1 + 16);
  if (ip != 0 && (ip < (uint64_t)epm || ip >= (uint64_t)epm + codelen))
    return 0;
  c->entry = (uint64_t)epm + 16;
  c->ppa1 = ppa1;
  c->epmflags = get32(epm + 12);
  c->dsa = c->epmflags & 0xFFFFFFE0u;
  c->gprmask = get16(ppa1 + 2);
  uint8_t flags3 = ppa1[10], flags4 = ppa1[11];
  const uint8_t *p = ppa1 + 20;
  if (flags3 & 0x40)            /* Länge des Argumentbereichs */
    p += 4;
  c->fprmask = 0;
  c->fprloc = 0;
  if (flags3 & 0x20) {          /* FPR-Maske, AR-Maske, FPR-Sicherungsbereich */
    c->fprmask = get16(p);
    c->fprloc = get32(p + 4);
    p += 8;
  }
  if (flags4 & 0x20)            /* VR-Maske */
    p += 8;
  c->haseh = 0;
  if (flags4 & 0x10) {          /* EH-Block */
    c->persdisp = get64(p + 8);
    c->lsdadisp = get64(p + 16);
    c->haseh = 1;
  }
  return 1;
}

/* Funktion zu einer Adresse im Code finden (EPM rückwärts suchen). */
static int find_function(uint64_t ip, struct _Unwind_Context *c)
{
  const uint8_t *p = (const uint8_t *)((ip - 2) & ~(uint64_t)1);
  const uint8_t *limit = p - (16u << 20);   /* höchstens 16 MB zurück */
  for (; p > limit; p -= 2)
    if (p[0] == 0x00 && p[1] == 0xC3 && parse_epm(p, ip, c))
      return 1;
  return 0;
}

/* Name der Funktion zu ip aus dem PPA1 (für Diagnosen), ASCII in buf.
 * Rückgabe 0, wenn keine Funktion oder kein Name gefunden wurde. */
int FPC_ZOS_FUNC_NAME(uint64_t ip, char *buf, int n)
{
  static const char e2a_digits[] = "0123456789";
  struct _Unwind_Context c;
  buf[0] = 0;
  if (n < 2 || !find_function(ip, &c))
    return 0;
  const uint8_t *ppa1 = c.ppa1;
  uint8_t flags3 = ppa1[10], flags4 = ppa1[11];
  const uint8_t *p = ppa1 + 20;
  if (flags3 & 0x40) p += 4;
  if (flags3 & 0x20) p += 8;
  if (flags4 & 0x20) p += 8;
  if (flags4 & 0x10) p += 24;
  if (!(flags4 & 0x01))
    return 0;
  int len = get16(p), k = 0;
  p += 2;
  for (int i = 0; i < len && k < n - 1; i++) {
    uint8_t e = p[i];
    char a = '?';
    if (e >= 0x81 && e <= 0x89) a = 'a' + (e - 0x81);
    else if (e >= 0x91 && e <= 0x99) a = 'j' + (e - 0x91);
    else if (e >= 0xA2 && e <= 0xA9) a = 's' + (e - 0xA2);
    else if (e >= 0xC1 && e <= 0xC9) a = 'A' + (e - 0xC1);
    else if (e >= 0xD1 && e <= 0xD9) a = 'J' + (e - 0xD1);
    else if (e >= 0xE2 && e <= 0xE9) a = 'S' + (e - 0xE2);
    else if (e >= 0xF0 && e <= 0xF9) a = e2a_digits[e - 0xF0];
    else if (e == 0x6D) a = '_';
    else if (e == 0x5B) a = '$';
    else if (e == 0x7B) a = '#';
    else if (e == 0x7C) a = '@';
    buf[k++] = a;
  }
  buf[k] = 0;
  return 1;
}

static uint64_t save_slot(const struct _Unwind_Context *c, int r)
{
  return c->gpr[4] + 2048 + 8 * (r - 4);
}

static int gpr_saved(const struct _Unwind_Context *c, int r)
{
  return (c->gprmask >> (15 - r)) & 1;
}

/* Umgebung (ADA) des Frames: R5 aus seinem Sicherungsbereich. */
static uint64_t frame_env(const struct _Unwind_Context *c)
{
  return gpr_saved(c, 5) ? *(uint64_t *)save_slot(c, 5) : 0;
}

/* Vom Frame c zum Frame seines Aufrufers. */
static int step(struct _Unwind_Context *c)
{
  if (c->epmflags & 0x08) {
    DBG("Blattfunktion im Stack\n");
    return 0;
  }
  if (c->epmflags & 0x04) {
    DBG("Funktion mit alloca wird nicht unterstützt\n");
    return 0;
  }
  if (!gpr_saved(c, 7))
    return 0;
  struct _Unwind_Context n = *c;
  for (int r = 5; r <= 15; r++)
    if (gpr_saved(c, r))
      n.gpr[r] = *(uint64_t *)save_slot(c, r);
  if (c->fprmask) {
    int basereg = c->fprloc >> 28;
    uint64_t a = c->gpr[basereg] + (c->fprloc & 0x0FFFFFFF);
    for (int k = 8; k <= 15; k++)
      if ((c->fprmask >> (15 - k)) & 1) {
        n.fpr[k] = *(uint64_t *)a;
        a += 8;
      }
  }
  n.gpr[4] = c->gpr[4] + c->dsa;
  n.ip = n.gpr[7] + 2;    /* XPLINK: Rücksprung hinter den NOP nach BASR */
  if (!find_function(n.ip, &n)) {
    DBG("keine Funktion zu ip=%llx\n", (unsigned long long)n.ip);
    return 0;
  }
  *c = n;
  return 1;
}

/* FPC_SYSTEMMAIN (System-Unit, vom main-Stub des Programms gerufen): dort endet
 * die Suche. Nicht main selbst: eine DLL hat kein main, und eine schwache
 * Referenz darauf bleibt beim Binden der DLL als unaufgelöst stehen. */
extern void FPC_SYSTEMMAIN(int, char **, char **);

static int is_main(const struct _Unwind_Context *c)
{
  return c->entry == ((uint64_t *)(void *)FPC_SYSTEMMAIN)[1];
}

/* Kontext für den Aufrufer der Funktion fn aufbauen; fn ist die gerade
 * laufende Funktion (die diesen Code enthält), regs/fregs ihr aktueller
 * Registerstand. */
static int init_context(struct _Unwind_Context *c, void *fn,
                        const uint64_t *regs, const uint64_t *fregs)
{
  if (debug < 0)
    debug = getenv("ZOS_UNWIND_DEBUG") != 0;
  memset(c, 0, sizeof *c);
  memcpy(c->gpr, regs, sizeof c->gpr);
  for (int k = 8; k <= 15; k++)
    c->fpr[k] = fregs[k - 8];
  /* Funktionszeiger zeigen auf den Deskriptor: +0 ADA, +8 Einsprung */
  uint64_t entry = ((uint64_t *)fn)[1];
  if (!parse_epm((const uint8_t *)(entry - 16), 0, c)) {
    DBG("kein EPM für die eigene Funktion\n");
    return 0;
  }
  return step(c);
}

#define CAPTURE(regs, fregs)                                              \
  __asm__ volatile(" stmg 0,15,0(%0)" : : "a"(regs) : "memory");         \
  __asm__ volatile(" std 8,0(%0)\n std 9,8(%0)\n std 10,16(%0)\n"         \
                   " std 11,24(%0)\n std 12,32(%0)\n std 13,40(%0)\n"     \
                   " std 14,48(%0)\n std 15,56(%0)"                       \
                   : : "a"(fregs) : "memory")

static void __attribute__((noreturn)) resume(struct _Unwind_Context *c)
{
  DBG("Sprung nach %llx, R4=%llx\n", (unsigned long long)c->ip,
      (unsigned long long)c->gpr[4]);
  __asm__ volatile(" lgr 1,%0\n"
                   " ld 8,192(1)\n ld 9,200(1)\n ld 10,208(1)\n ld 11,216(1)\n"
                   " ld 12,224(1)\n ld 13,232(1)\n ld 14,240(1)\n ld 15,248(1)\n"
                   " lg 3,256(1)\n"
                   " lg 2,16(1)\n"
                   " lg 4,32(1)\n"
                   " lmg 5,15,40(1)\n"
                   " lg 1,8(1)\n"
                   " br 3"
                   : : "a"(c) : "memory");
  __builtin_unreachable();
}

static personality_fn frame_personality(const struct _Unwind_Context *c)
{
  if (!c->haseh)
    return 0;
  uint64_t env = frame_env(c);
  if (!env)
    return 0;
  return (personality_fn)(*(void **)(env + c->persdisp));
}

static _Unwind_Reason_Code phase2(struct _Unwind_Exception *e,
                                  struct _Unwind_Context *c)
{
  for (;;) {
    personality_fn pers = frame_personality(c);
    int handler = c->gpr[4] == e->private_2;
    if (pers) {
      _Unwind_Action a = _UA_CLEANUP_PHASE | (handler ? _UA_HANDLER_FRAME : 0);
      _Unwind_Reason_Code rc = pers(1, a, e->exception_class, e, c);
      DBG("Phase 2: ip=%llx rc=%d\n", (unsigned long long)c->ip, rc);
      if (rc == _URC_INSTALL_CONTEXT) {
        /* im Landing Pad gilt die eigene Umgebung des Frames */
        c->gpr[5] = frame_env(c);
        resume(c);
      }
      if (rc != _URC_CONTINUE_UNWIND)
        return _URC_FATAL_PHASE2_ERROR;
    }
    if (handler || is_main(c) || !step(c))
      return _URC_FATAL_PHASE2_ERROR;
  }
}

_Unwind_Reason_Code _Unwind_RaiseException(struct _Unwind_Exception *e)
{
  uint64_t regs[16], fregs[8];
  struct _Unwind_Context c;
  CAPTURE(regs, fregs);
  if (!init_context(&c, (void *)_Unwind_RaiseException, regs, fregs))
    return _URC_END_OF_STACK;
  struct _Unwind_Context start = c;
  /* Phase 1: Handler suchen */
  for (;;) {
    personality_fn pers = frame_personality(&c);
    if (pers) {
      _Unwind_Reason_Code rc = pers(1, _UA_SEARCH_PHASE, e->exception_class, e, &c);
      DBG("Phase 1: ip=%llx rc=%d\n", (unsigned long long)c.ip, rc);
      if (rc == _URC_HANDLER_FOUND) {
        e->private_2 = c.gpr[4];
        break;
      }
      if (rc != _URC_CONTINUE_UNWIND)
        return _URC_FATAL_PHASE1_ERROR;
    }
    if (is_main(&c) || !step(&c))
      return _URC_END_OF_STACK;
  }
  /* Phase 2: aufräumen und in den Handler springen */
  return phase2(e, &start);
}

void _Unwind_Resume(struct _Unwind_Exception *e)
{
  uint64_t regs[16], fregs[8];
  struct _Unwind_Context c;
  CAPTURE(regs, fregs);
  if (init_context(&c, (void *)_Unwind_Resume, regs, fregs))
    phase2(e, &c);
  fprintf(stderr, "zosunwind: _Unwind_Resume fehlgeschlagen\n");
  abort();
}

_Unwind_Reason_Code _Unwind_Resume_or_Rethrow(struct _Unwind_Exception *e)
{
  return _Unwind_RaiseException(e);
}

void _Unwind_DeleteException(struct _Unwind_Exception *e)
{
  if (e && e->exception_cleanup)
    e->exception_cleanup(_URC_FOREIGN_EXCEPTION_CAUGHT, e);
}

uintptr_t _Unwind_GetLanguageSpecificData(struct _Unwind_Context *c)
{
  uint64_t env;
  if (!c->haseh || !(env = frame_env(c)))
    return 0;
  return *(uint64_t *)(env + c->lsdadisp);
}

uintptr_t _Unwind_GetRegionStart(struct _Unwind_Context *c) { return c->entry; }
uintptr_t _Unwind_GetIP(struct _Unwind_Context *c) { return c->ip; }
void _Unwind_SetIP(struct _Unwind_Context *c, uintptr_t v) { c->ip = v; }
uintptr_t _Unwind_GetGR(struct _Unwind_Context *c, int i) { return (i >= 0 && i < 16) ? c->gpr[i] : 0; }
void _Unwind_SetGR(struct _Unwind_Context *c, int i, uintptr_t v) { if (i >= 0 && i < 16) c->gpr[i] = v; }
uintptr_t _Unwind_GetDataRelBase(struct _Unwind_Context *c) { (void)c; return 0; }
uintptr_t _Unwind_GetTextRelBase(struct _Unwind_Context *c) { (void)c; return 0; }
uintptr_t _Unwind_GetCFA(struct _Unwind_Context *c) { return c->gpr[4]; }
