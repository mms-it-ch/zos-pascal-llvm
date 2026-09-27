int initialized4 = 0;
__attribute__((constructor)) void cdll4_init(void) { initialized4 = 42; }
__attribute__((visibility("default"))) int cdll4_value(void) { return initialized4; }
