#include <stdio.h>
int cdll2_value(void);
int main(void) { int v = cdll2_value(); printf("cdll2_value = %d\n", v); return v == 142 ? 0 : 1; }
