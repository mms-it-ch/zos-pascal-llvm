/* iconv-Namen im ASCII-Modus (wie cwstring sie verwendet) */
#include <iconv.h>
#include <stdio.h>
#include <string.h>
static void t(const char *to, const char *from)
{
  iconv_t cd = iconv_open(to, from);
  unsigned char in[1] = { 0x80 }, out[8];
  char *ip = (char *)in, *op = (char *)out;
  size_t il = 1, ol = sizeof out, i;
  if (cd == (iconv_t)-1) { printf("%s <- %s: iconv_open FEHLER\n", to, from); return; }
  iconv(cd, &ip, &il, &op, &ol);
  printf("%s <- %s:", to, from);
  for (i = 0; i < sizeof out - ol; i++) printf(" %02X", out[i]);
  printf("\n");
  iconv_close(cd);
}
int main(void)
{
  t("1200", "1253"); t("1200", "CP1253"); t("1200", "IBM-1253"); t("UTF-8", "IBM-1253");
  t("1200", "ISO8859-1"); t("1200", "ISO-8859-1");
  return 0;
}
