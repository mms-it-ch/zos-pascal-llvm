/* Attrappe der z/OS-Erweiterungen von <stdio.h> für den x86-Prüfstand von
 * runtime/zosdsn.c (mit -include eingebunden). */
#include <stdio.h>
#include <stddef.h>
typedef struct {
  int __dsorgVSAM, __recfmF, __recfmV, __vsamtype;
  long __maxreclen;
  unsigned __vsamkeylen, __vsamRKP;
} fldata_t;
static inline int fldata(FILE *f, char *n, fldata_t *i) { (void)f; (void)n; (void)i; return -1; }
static inline int flocate(FILE *f, const void *k, size_t l, int o) { (void)f; (void)k; (void)l; (void)o; return -1; }
static inline size_t fupdate(const void *b, size_t n, FILE *f) { (void)b; (void)n; (void)f; return 0; }
static inline int fdelrec(FILE *f) { (void)f; return -1; }
