/* PF4: C-DLL mit Konstruktor (C_@@SQINIT) - läuft der Konstruktor beim Laden? */
#include <stdio.h>
int initialized = 0;  /* global, hidden, eigener Abschnitt */
__attribute__((constructor)) void cdll_init(void) { initialized = 42; }  /* global, hidden */
__attribute__((visibility("default"))) int cdll_value(void) { return initialized; }
__attribute__((destructor)) void cdll_fini(void) { initialized = 0; }
