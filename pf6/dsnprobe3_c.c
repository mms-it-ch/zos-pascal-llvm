/* PF6: Behält fopen("w") die Attribute eines vorhandenen Datasets? */
#define _EXT 1
#include <stdio.h>
#include <errno.h>

static void attrs(const char *what, FILE *f)
{
  fldata_t fl;
  if (fldata(f, 0, &fl) == 0)
    printf("  %-28s recfmF=%d recfmV=%d recfmU=%d lrecl=%lu blksize=%lu\n", what,
           fl.__recfmF, fl.__recfmV, fl.__recfmU, (unsigned long)fl.__maxreclen,
           (unsigned long)fl.__blksize);
}

int main(void)
{
  const char *dsn = "//ZPAS.TEST.ATTR";
  const char *modes[] = { "w", "wb", "w,recfm=*", "wb,recfm=*", "a", "r+" };
  remove(dsn);
  for (int i = 0; i < 6; i++) {
    FILE *f = fopen(dsn, "w,recfm=fb,lrecl=80,space=(trk,(1,1))");
    if (!f) { printf("anlegen: errno %d\n", errno); return 1; }
    attrs("angelegt", f);
    fputs("x\n", f);
    fclose(f);
    f = fopen(dsn, modes[i]);
    if (!f) { printf("  %-28s errno %d\n", modes[i], errno); continue; }
    attrs(modes[i], f);
    fclose(f);
    remove(dsn);
  }
  return 0;
}
