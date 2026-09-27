/* Funktionszeiger-Gleichheit auf z/OS (XPLINK-Deskriptoren): statischer
 * Initialisierer vs. Adresse im Code */
#include <stdio.h>
void f(void) {}
static void g(void) {}
void (*pf)(void) = f;
void (*pg)(void) = g;
int main(void)
{
  void (*volatile lf)(void) = f;
  void (*volatile lg)(void) = g;
  printf("f: code %p statisch %p -> %s\n", (void *)lf, (void *)pf, lf == pf ? "gleich" : "VERSCHIEDEN");
  printf("g: code %p statisch %p -> %s\n", (void *)lg, (void *)pg, lg == pg ? "gleich" : "VERSCHIEDEN");
  return (lf == pf && lg == pg) ? 0 : 1;
}
