/* PF4: schwache externe Referenzen (weakexternal) auf nicht vorhandene Symbole */
#include <stdio.h>
extern int wv __attribute__((weak));
extern void wf(void) __attribute__((weak));
int main(void)
{
  printf("&wv %s, wf %s\n", &wv ? "da" : "nil", wf ? "da" : "nil");
  return (&wv ? 1 : 0) + (wf ? 2 : 0);
}
