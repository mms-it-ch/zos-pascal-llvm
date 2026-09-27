/* PF4: Pascal-DLL aus C laden: stürzt der Konstruktor oder erst der Aufruf ab? */
#include <dlfcn.h>
#include <stdio.h>
int main(int argc, char **argv)
{
  const char *lib = argc > 1 ? argv[1] : "libdv.so";
  const char *sym = argc > 2 ? argv[2] : "dv_value";
  void *h; int (*f)(void);
  printf("dlopen(%s) ...\n", lib); fflush(stdout);
  h = dlopen(lib, RTLD_NOW);
  printf("dlopen = %p %s\n", h, h ? "" : dlerror()); fflush(stdout);
  if (!h) return 1;
  f = (int (*)(void))dlsym(h, sym);
  printf("dlsym(%s) = %p, Einsprung %p\n", sym, (void *)f, f ? ((void **)f)[1] : 0); fflush(stdout);
  if (!f) return 2;
  printf("Aufruf ...\n"); fflush(stdout);
  printf("Ergebnis %d\n", f());
  return 0;
}
