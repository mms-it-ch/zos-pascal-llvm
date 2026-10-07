/* Attrappe der AMODE-31-Brücke pf8/zpcall31.s für Tests auf x86_64 (gleiches Protokoll,
 * runtime/zosc31.c). Statt LOAD/BASSM kennt sie zwei "Programme" mit derselben
 * Wirkung wie die echten Testprogramme in pf8/:
 *   ZPASM1 (HLASM):  P3 := P1 + P2 (Fullwords), R15 = 0; ist P1 negativ: R15 = 8
 *   ZPCOB1 (COBOL, Satz KUNDE-SATZ aus tests/copybooks/kunde.cpy):
 *            KUNDE-SALDO := KUNDE-SALDO + 100.50, KUNDE-STATUS := 'A',
 *            KUNDE-PUNKTE := KUNDE-ANZAHL * 10, RETURN-CODE 4
 * Andere Namen: Status 1 (LOAD gescheitert, Code X'806'). */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void rd(void *p, size_t n)
{
  size_t k = 0;
  while (k < n) {
    ssize_t r = read(0, (char *)p + k, n - k);
    if (r <= 0)
      exit(r == 0 ? 0 : 3);
    k += (size_t)r;
  }
}

static void wr(const void *p, size_t n)
{
  if (write(1, p, n) != (ssize_t)n)
    exit(3);
}

static unsigned long g32(const unsigned char *b)
{
  return ((unsigned long)b[0] << 24) | ((unsigned long)b[1] << 16) | ((unsigned long)b[2] << 8) | b[3];
}

static void p32(unsigned char *b, unsigned long v)
{
  b[0] = (unsigned char)(v >> 24); b[1] = (unsigned char)(v >> 16);
  b[2] = (unsigned char)(v >> 8); b[3] = (unsigned char)v;
}

static void w32(unsigned long v)
{
  unsigned char b[4];
  p32(b, v);
  wr(b, 4);
}

/* gepackt <-> long long (Vorzeichen C/D) */
static long long unpack(const unsigned char *p, int len)
{
  long long v = 0;
  for (int i = 0; i < len; i++) {
    v = v * 10 + (p[i] >> 4);
    if (i < len - 1)
      v = v * 10 + (p[i] & 15);
  }
  return ((p[len - 1] & 15) == 0xD) ? -v : v;
}

static void pack(unsigned char *p, int len, long long v)
{
  int neg = v < 0;
  if (neg)
    v = -v;
  p[len - 1] = (unsigned char)(((v % 10) << 4) | (neg ? 0xD : 0xC));
  v /= 10;
  for (int i = len - 2; i >= 0; i--) {
    p[i] = (unsigned char)(v % 10);
    v /= 10;
    p[i] |= (unsigned char)((v % 10) << 4);
    v /= 10;
  }
}

int main(void)
{
  for (;;) {
    unsigned char b[4], name[8], *area[32];
    unsigned long len[32], n, magic, rc = 0;
    rd(b, 4);
    magic = g32(b);
    if (magic == 0xE9F3F1C5u)
      return 0;
    if (magic != 0xE9F3F1C3u)
      return 2;
    rd(name, 8);
    rd(b, 4);
    n = g32(b);
    if (n > 32)
      return 2;
    for (unsigned long i = 0; i < n; i++) {
      rd(b, 4);
      len[i] = g32(b);
      area[i] = malloc(len[i] ? len[i] : 1);
      rd(area[i], len[i]);
    }
    /* EBCDIC: ZPASM1 = E9 D7 C1 E2 D4 F1, ZPCOB1 = E9 D7 C3 D6 C2 F1 */
    if (memcmp(name, "\xE9\xD7\xC1\xE2\xD4\xF1\x40\x40", 8) == 0 && n == 3) {
      long a = (long)(int)g32(area[0]), c = (long)(int)g32(area[1]);
      p32(area[2], (unsigned long)(a + c));
      rc = a < 0 ? 8 : 0;
    } else if (memcmp(name, "\xE9\xD7\xC3\xD6\xC2\xF1\x40\x40", 8) == 0 && n == 1 && len[0] == 97) {
      unsigned char *k = area[0];
      pack(k + 39, 6, unpack(k + 39, 6) + 10050);
      k[38] = 0xC1;
      p32(k + 52, (unsigned long)(((k[50] << 8) | k[51]) * 10));
      rc = 4;
    } else {
      w32(0xE9F3F1D9u); w32(1); w32(0x806);
      for (unsigned long i = 0; i < n; i++) free(area[i]);
      continue;
    }
    w32(0xE9F3F1D9u); w32(0); w32(rc);
    for (unsigned long i = 0; i < n; i++) {
      w32(len[i]);
      wr(area[i], len[i]);
      free(area[i]);
    }
  }
}
