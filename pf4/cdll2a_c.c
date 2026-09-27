/* PF4: Funktionszeiger auf eine versteckte Funktion einer anderen Übersetzungseinheit
 * in einer DLL (Code: VD(f@indirect)) */
int hidden_f(void);
int (*table[1])(void) = { hidden_f };      /* statischer Initialisierer */
__attribute__((visibility("default"))) int cdll2_value(void)
{
  int (*volatile p)(void) = hidden_f;       /* Adresse im Code */
  return p() + table[0]() + (p == table[0] ? 100 : 0);
}
