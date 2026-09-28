/* PF6: neues PDS/PDSE zusammen mit dem ersten Member anlegen - wo scheitert es? */
#define _EXT 1
#include <stdio.h>
#include <errno.h>
#include <string.h>

static void probe(const char *lib, const char *attr)
{
  char name[80], mode[120];
  snprintf(name, sizeof name, "//%s(MEMA)", lib);
  snprintf(mode, sizeof mode, "w,%s", attr);
  errno = 0;
  FILE *f = fopen(name, mode);
  printf("%s: fopen(%s) = %p errno %d %s\n", lib, mode, (void *)f, errno, f ? "" : strerror(errno));
  if (f) {
    errno = 0;
    int w = fputs("\xC1\x15", f);
    int c = fclose(f);
    printf("  fputs %d, fclose %d errno %d\n", w, c, errno);
  }
  snprintf(name, sizeof name, "//%s", lib);
  printf("  remove lib: %d\n", remove(name));
}

int main(void)
{
  probe("ZPAS.TEST.PDS", "recfm=fb,lrecl=80,dsorg=po,space=(trk,(1,1,5))");
  probe("ZPAS.TEST.PDS", "recfm=fb,lrecl=80,space=(trk,(1,1,5))");
  probe("ZPAS.TEST.PDSE", "recfm=fb,lrecl=80,dsntype=library,space=(trk,(1,1,5))");
  return 0;
}
