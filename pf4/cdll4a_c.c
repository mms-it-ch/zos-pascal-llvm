/* PF4: großes Objekt vor dem Objekt mit Konstruktor (QD-Offset <> 0) */
int big_data[4096] = { 1 };
int big_value(void) { return big_data[0]; }
