#include <stdio.h>
int cdll4_value(void);
int main(void) { printf("vor dem Aufruf\n"); fflush(stdout); int v = cdll4_value(); printf("cdll4_value = %d\n", v); return v == 42 ? 0 : 1; }
