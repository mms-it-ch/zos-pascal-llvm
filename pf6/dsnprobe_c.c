/* PF6: Verhalten der C-Laufzeit (ASCII-Modus, AMODE 64) bei MVS-Datasets.
 * Legt <Präfix>.ZPAS.TEST.FB80 und .VB255 an, schreibt und liest sie
 * satzweise (type=record) und im Textmodus, und löscht sie wieder. */
#include <stdio.h>
#include <string.h>
#include <errno.h>

static void hex(const char *what, const unsigned char *b, int n)
{
  printf("  %s (%d):", what, n);
  for (int i = 0; i < n && i < 24; i++)
    printf(" %02X", b[i]);
  printf("%s\n", n > 24 ? " ..." : "");
}

static void probe(const char *dsn, const char *attr)
{
  char mode[80];
  unsigned char buf[400];
  FILE *f;
  printf("== %s (%s)\n", dsn, attr);
  remove(dsn);
  snprintf(mode, sizeof mode, "wb,type=record,%s", attr);
  f = fopen(dsn, mode);
  if (!f) { printf("  fopen w: errno %d %s\n", errno, strerror(errno)); return; }
  printf("  fileno: %d\n", fileno(f));
  /* EBCDIC: "ABC" = C1 C2 C3, dann kurzer und langer Satz */
  printf("  fwrite 3: %zu\n", fwrite("\xC1\xC2\xC3", 1, 3, f));
  memset(buf, 0xF1, 80);
  printf("  fwrite 80: %zu\n", fwrite(buf, 1, 80, f));
  memset(buf, 0xF2, 100);
  printf("  fwrite 100: %zu (errno %d)\n", fwrite(buf, 1, 100, f), errno);
  printf("  fwrite 0: %zu\n", fwrite(buf, 1, 0, f));
  fclose(f);

  f = fopen(dsn, "rb,type=record");
  if (!f) { printf("  fopen r: errno %d\n", errno); return; }
  for (int k = 0; k < 6; k++) {
    size_t n = fread(buf, 1, sizeof buf, f);
    if (n == 0 && feof(f)) { printf("  EOF nach %d Sätzen\n", k); break; }
    char w[16]; snprintf(w, sizeof w, "Satz %d", k);
    hex(w, buf, (int)n);
  }
  fclose(f);

  f = fopen(dsn, "rb");
  if (f) {
    size_t n = fread(buf, 1, sizeof buf, f);
    hex("Bytestrom", buf, (int)n);
    printf("  Bytestrom gesamt: %zu\n", n);
    fclose(f);
  }
  f = fopen(dsn, "r");
  if (f) {
    size_t n = fread(buf, 1, sizeof buf, f);
    hex("Textmodus", buf, (int)n);
    printf("  Textmodus gesamt: %zu\n", n);
    fclose(f);
  }
  printf("  remove: %d\n", remove(dsn));
}

int main(void)
{
  probe("//ZPAS.TEST.FB80", "recfm=fb,lrecl=80,space=(trk,(1,1))");
  probe("//ZPAS.TEST.VB255", "recfm=vb,lrecl=255,space=(trk,(1,1))");
  FILE *f = fopen("//ZPAS.TEST.NOTEXIST", "rb");
  printf("== nicht vorhanden: %p errno %d\n", (void *)f, errno);
  return 0;
}
