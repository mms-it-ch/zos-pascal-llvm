/* PF4: Programm, das cdll über das Sidedeck bindet */
#include <stdio.h>
int cdll_value(void);
int main(void) { int v = cdll_value(); printf("cdll_value = %d\n", v); return v == 42 ? 0 : 1; }
