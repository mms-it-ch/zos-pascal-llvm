/* PF4: DLL-intern Aufruf einer versteckten Funktion einer anderen
 * Übersetzungseinheit, die globale Daten liest (RD/VD-Deskriptor im ADA) */
int hidden_get(void);
__attribute__((visibility("default"))) int cdll3_value(void) { return hidden_get(); }
