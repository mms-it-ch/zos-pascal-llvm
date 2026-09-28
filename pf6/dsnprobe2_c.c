/* PF6: Textmodus der C-Laufzeit bei MVS-Datasets (ASCII-Programm): Schreiben mit
 * X'15' als Zeilenende, Leerzeile, zu lange Zeile, Auffüllen bei FB, Lesen mit
 * nachgestellten Leerzeichen; Satzattribute über fldata. */
#define _EXT 1
#include <stdio.h>
#include <string.h>
#include <errno.h>

static void hex(const char *what, const unsigned char *b, int n)
{
  printf("  %s (%d):", what, n);
  for (int i = 0; i < n && i < 40; i++)
    printf(" %02X", b[i]);
  printf("%s\n", n > 40 ? " ..." : "");
}

static void probe(const char *dsn, const char *attr)
{
  char mode[80];
  unsigned char buf[600];
  FILE *f;
  fldata_t fl;
  printf("== %s (%s)\n", dsn, attr);
  remove(dsn);
  snprintf(mode, sizeof mode, "w,%s", attr);
  f = fopen(dsn, mode);
  if (!f) { printf("  fopen w: errno %d %s\n", errno, strerror(errno)); return; }
  if (fldata(f, 0, &fl) == 0)
    printf("  fldata: recfmF=%d recfmV=%d recfmU=%d blksize=%lu lrecl=%lu dsorg=%d\n",
           fl.__recfmF, fl.__recfmV, fl.__recfmU, (unsigned long)fl.__blksize,
           (unsigned long)fl.__maxreclen, fl.__dsorgPS);
  /* "AB  " + NL, Leerzeile, 100 x '1' + NL, "C" ohne NL */
  fwrite("\xC1\xC2\x40\x40\x15", 1, 5, f);
  fwrite("\x15", 1, 1, f);
  memset(buf, 0xF1, 100); buf[100] = 0x15;
  printf("  fwrite 101: %zu errno %d\n", fwrite(buf, 1, 101, f), errno);
  fwrite("\xC3", 1, 1, f);
  printf("  fclose: %d errno %d\n", fclose(f), errno);

  f = fopen(dsn, "rb,type=record");
  for (int k = 0; f && k < 8; k++) {
    size_t n = fread(buf, 1, sizeof buf, f);
    if (n == 0 && feof(f)) { printf("  EOF nach %d Sätzen\n", k); break; }
    char w[16]; snprintf(w, sizeof w, "Satz %d", k);
    hex(w, buf, (int)n);
  }
  if (f) fclose(f);
  f = fopen(dsn, "r");
  if (f) {
    size_t n = fread(buf, 1, sizeof buf, f);
    hex("Textmodus", buf, (int)n);
    fclose(f);
  }
  printf("  remove: %d\n", remove(dsn));
}

int main(void)
{
  probe("//ZPAS.TEST.FB80", "recfm=fb,lrecl=80,space=(trk,(1,1))");
  probe("//ZPAS.TEST.VB255", "recfm=vb,lrecl=255,space=(trk,(1,1))");
  return 0;
}
