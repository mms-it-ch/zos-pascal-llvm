/* Attrappe von <dynit.h> (z/OS) für den x86-Prüfstand von runtime/zosdsn.c: nur was
 * zosdsn.c benutzt; dynalloc schlägt immer fehl. Werte ohne Bedeutung. */
typedef struct {
  char *__dsname;
  int __status, __normdisp, __conddisp, __dsorg, __dsntype, __alcunit;
  int __primary, __secondary, __dirblk, __recfm;
  unsigned short __lrecl;
  short __blksize;
} __dyn_t;
enum { __DISP_NEW = 1, __DISP_CATLG, __DISP_DELETE, __DSORG_PO, __DSNT_LIBRARY, __DSNT_PDS,
       __TRK, __CYL, _F_, _FB_, _V_, _VB_, _U_ };
static inline void dyninit(__dyn_t *d) { (void)d; }
static inline int dynalloc(__dyn_t *d) { (void)d; return -1; }
static inline int dynfree(__dyn_t *d) { (void)d; return 0; }
