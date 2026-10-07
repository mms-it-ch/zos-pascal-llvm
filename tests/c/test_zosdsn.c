/* x86-Prüfstand für die CCSID-Logik von runtime/zosdsn.c (ohne z/OS): Tabellen,
 * Standard-CCSID aus ZOS_CCSID, Zusatz ",ccsid=NNN" und FPC_ZOS_DSN_SET_CCSID.
 * Unter Linux legt fopen("DD:NAME") eine gewöhnliche Datei dieses Namens an; so laufen
 * Text-Lesen/-Schreiben samt Umwandlung durch dieselben Routinen wie auf z/OS.
 *
 *   tests/run-x86.sh   (übersetzt mit den Attrappen in tests/c/stub)
 *   test_zosdsn [erwartete Standard-CCSID]
 */
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int FPC_ZOS_DSN_OPEN(const char *name, int mode, int text);
long FPC_ZOS_DSN_READ(int h, void *buf, long n);
long FPC_ZOS_DSN_WRITE(int h, const void *buf, long n);
int FPC_ZOS_DSN_CLOSE(int h);
int FPC_ZOS_E2A_CCSID(unsigned char *p, long n, int ccsid);
int FPC_ZOS_A2E_CCSID(unsigned char *p, long n, int ccsid);
void FPC_ZOS_E2A(unsigned char *p, long n);
void FPC_ZOS_A2E(unsigned char *p, long n);
int FPC_ZOS_CCSID_SET_DEFAULT(int ccsid);
int FPC_ZOS_CCSID_DEFAULT(void);
int FPC_ZOS_CCSID_SUPPORTED(int ccsid);
int FPC_ZOS_DSN_SET_CCSID(int h, int ccsid);
int FPC_ZOS_DSN_GET_CCSID(int h);

static int errors, checks;
#define CHECK(c, ...) do { checks++; if (!(c)) { errors++; printf("FEHLER  " __VA_ARGS__); printf("\n"); } } while (0)

static const int ccsids[] = { 1047, 37, 273, 277, 278, 280, 284, 285, 297, 500, 871,
                              1140, 1141, 1142, 1143, 1144, 1145, 1146, 1147, 1148, 1149 };
#define N (sizeof ccsids / sizeof ccsids[0])

static long slurp(const char *fn, unsigned char *buf, long max)
{
  FILE *f = fopen(fn, "rb");
  long n;
  if (!f)
    return -1;
  n = (long)fread(buf, 1, (size_t)max, f);
  fclose(f);
  return n;
}

int main(int argc, char **argv)
{
  unsigned char all[256], t[256], buf[512];
  int expect_default = argc > 1 ? atoi(argv[1]) : 1047;
  int h;
  long n;

  for (int i = 0; i < 256; i++)
    all[i] = (unsigned char)i;

  CHECK(FPC_ZOS_CCSID_DEFAULT() == expect_default, "Standard-CCSID %d, erwartet %d",
        FPC_ZOS_CCSID_DEFAULT(), expect_default);

  /* Rundreise und Umkehrbarkeit je CCSID */
  for (size_t k = 0; k < N; k++) {
    int seen[256] = { 0 }, perm = 1;
    memcpy(t, all, 256);
    CHECK(FPC_ZOS_A2E_CCSID(t, 256, ccsids[k]) == 0, "A2E %d", ccsids[k]);
    for (int i = 0; i < 256; i++)
      if (seen[t[i]]++)
        perm = 0;
    CHECK(perm, "CCSID %d: A2E nicht umkehrbar", ccsids[k]);
    CHECK(FPC_ZOS_E2A_CCSID(t, 256, ccsids[k]) == 0, "E2A %d", ccsids[k]);
    CHECK(memcmp(t, all, 256) == 0, "CCSID %d: Rundreise", ccsids[k]);
    /* Ziffern, Leerzeichen und LF sind in allen CECP-Codepages gleich */
    memcpy(t, "0123456789 \n", 12);
    FPC_ZOS_A2E_CCSID(t, 12, ccsids[k]);
    CHECK(memcmp(t, "\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\x40\x15", 12) == 0,
          "CCSID %d: Ziffern/Leerzeichen/NL", ccsids[k]);
  }
  CHECK(FPC_ZOS_CCSID_SUPPORTED(273) && !FPC_ZOS_CCSID_SUPPORTED(1208), "SUPPORTED");
  memcpy(t, "A", 1);
  CHECK(FPC_ZOS_A2E_CCSID(t, 1, 4711) == -1 && errno == EINVAL && t[0] == 'A', "unbekannte CCSID");

  /* Stichproben (IBM-Tabellen): Ä in 273 = X'4A', @ in 273 = X'B5', [ in 1047 = X'AD',
   * [ in 37 = X'BA', Euro (ASCII X'A4') in 1141 = X'9F', ¤ in 273 = X'9F' */
  t[0] = 0xC4; FPC_ZOS_A2E_CCSID(t, 1, 273); CHECK(t[0] == 0x4A, "Ä 273: %02X", t[0]);
  t[0] = '@'; FPC_ZOS_A2E_CCSID(t, 1, 273); CHECK(t[0] == 0xB5, "@ 273: %02X", t[0]);
  t[0] = '['; FPC_ZOS_A2E_CCSID(t, 1, 1047); CHECK(t[0] == 0xAD, "[ 1047: %02X", t[0]);
  t[0] = '['; FPC_ZOS_A2E_CCSID(t, 1, 37); CHECK(t[0] == 0xBA, "[ 37: %02X", t[0]);
  t[0] = 0xA4; FPC_ZOS_A2E_CCSID(t, 1, 1141); CHECK(t[0] == 0x9F, "Euro 1141: %02X", t[0]);

  /* Standard ändern: FPC_ZOS_A2E folgt */
  CHECK(FPC_ZOS_CCSID_SET_DEFAULT(4711) == -1, "SET_DEFAULT unbekannt");
  CHECK(FPC_ZOS_CCSID_SET_DEFAULT(500) == 0 && FPC_ZOS_CCSID_DEFAULT() == 500, "SET_DEFAULT 500");
  t[0] = '!'; FPC_ZOS_A2E(t, 1); CHECK(t[0] == 0x4F, "! 500: %02X", t[0]);
  t[0] = 0x4F; FPC_ZOS_E2A(t, 1); CHECK(t[0] == '!', "E2A 500");
  FPC_ZOS_CCSID_SET_DEFAULT(expect_default);

  /* Textdatei mit eigenem Zusatz ,ccsid=273: Datei enthält EBCDIC 273, Lesen gibt Latin-1 */
  remove("DD:CCSIDT1");
  h = FPC_ZOS_DSN_OPEN("DD:CCSIDT1,ccsid=273", 1, 1);
  CHECK(h >= 0x7F000000, "OPEN schreiben (%d, errno %d)", h, errno);
  CHECK(FPC_ZOS_DSN_GET_CCSID(h) == 273, "GET_CCSID 273");
  CHECK(FPC_ZOS_DSN_WRITE(h, "\xC4@[\n", 4) == 4, "WRITE");
  CHECK(FPC_ZOS_DSN_CLOSE(h) == 0, "CLOSE");
  n = slurp("DD:CCSIDT1", buf, sizeof buf);
  CHECK(n == 4 && memcmp(buf, "\x4A\xB5\x63\x15", 4) == 0, "Inhalt 273: %ld %02X %02X %02X %02X",
        n, buf[0], buf[1], buf[2], buf[3]);
  h = FPC_ZOS_DSN_OPEN("DD:CCSIDT1,ccsid=273", 0, 1);
  n = FPC_ZOS_DSN_READ(h, buf, sizeof buf);
  CHECK(n == 4 && memcmp(buf, "\xC4@[\n", 4) == 0, "Lesen 273");
  FPC_ZOS_DSN_CLOSE(h);
  /* derselbe Inhalt mit dem Standard gelesen: andere Zeichen */
  h = FPC_ZOS_DSN_OPEN("DD:CCSIDT1", 0, 1);
  CHECK(FPC_ZOS_DSN_GET_CCSID(h) == expect_default, "GET_CCSID Standard");
  CHECK(FPC_ZOS_DSN_SET_CCSID(h, 4711) == -1 && errno == EINVAL, "SET_CCSID unbekannt");
  CHECK(FPC_ZOS_DSN_SET_CCSID(h, 273) == 0, "SET_CCSID 273");
  n = FPC_ZOS_DSN_READ(h, buf, sizeof buf);
  CHECK(n == 4 && memcmp(buf, "\xC4@[\n", 4) == 0, "Lesen nach SET_CCSID");
  FPC_ZOS_DSN_CLOSE(h);
  CHECK(FPC_ZOS_DSN_SET_CCSID(12345, 273) == -1 && errno == EBADF, "SET_CCSID ohne Handle");
  /* unbekannte CCSID im Namen: EINVAL, keine Datei */
  remove("DD:CCSIDT2");
  CHECK(FPC_ZOS_DSN_OPEN("DD:CCSIDT2,ccsid=999", 1, 1) == -1 && errno == EINVAL, "OPEN ccsid=999");
  CHECK(slurp("DD:CCSIDT2", buf, 1) < 0, "keine Datei bei ccsid=999");
  /* Binärdateien: keine Umwandlung, auch mit ccsid */
  h = FPC_ZOS_DSN_OPEN("DD:CCSIDT1,ccsid=273", 1, 0);
  FPC_ZOS_DSN_WRITE(h, "\xC4@", 2);
  FPC_ZOS_DSN_CLOSE(h);
  n = slurp("DD:CCSIDT1", buf, sizeof buf);
  CHECK(n == 2 && memcmp(buf, "\xC4@", 2) == 0, "binär unverändert");
  remove("DD:CCSIDT1");

  printf("zosdsn (x86): %d/%d Prüfungen ok\n", checks - errors, checks);
  return errors != 0;
}
