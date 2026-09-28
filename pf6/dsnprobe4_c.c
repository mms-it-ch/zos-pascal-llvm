/* PF6: recfm=* und recfm=+ bei einem noch nicht vorhandenen Dataset */
#define _EXT 1
#include <stdio.h>
#include <errno.h>

int main(void)
{
  const char *dsn = "//ZPAS.TEST.NEU";
  const char *modes[] = { "w,recfm=*", "w,recfm=+", "wb,recfm=*" };
  for (int i = 0; i < 3; i++) {
    fldata_t fl;
    remove(dsn);
    FILE *f = fopen(dsn, modes[i]);
    if (!f) { printf("  %-12s errno %d\n", modes[i], errno); continue; }
    if (fldata(f, 0, &fl) == 0)
      printf("  %-12s recfmF=%d recfmV=%d lrecl=%lu\n", modes[i], fl.__recfmF, fl.__recfmV,
             (unsigned long)fl.__maxreclen);
    fclose(f);
    remove(dsn);
  }
  return 0;
}
