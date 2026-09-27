#include <stdio.h>
int cdll3_value(void);
int main(void) { printf("vor dem Aufruf\n"); fflush(stdout); int v = cdll3_value(); printf("cdll3_value = %d\n", v); return v == 42 ? 0 : 1; }
