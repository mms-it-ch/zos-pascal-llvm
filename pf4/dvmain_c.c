/* PF4: C-Programm, das die Pascal-DLL libdv implizit (Sidedeck) bindet */
#include <stdio.h>
int dv_value(void);
int main(void) { printf("vor dem Aufruf\n"); fflush(stdout); printf("dv_value = %d\n", dv_value()); return 0; }
