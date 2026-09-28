/* zoslines0.c - leere Zeilentabelle (Programme ohne -gl).
 * Mit -gl erzeugt zos-ld aus den DWARF-Daten der Objekte (D_LINE) eine
 * Tabelle gleichen Namens (scripts/goff-lines.py) und bindet sie statt dieser
 * mit; die Laufzeit (zosunwind.c, FPC_ZOS_FUNC_LINE) sucht darin. */
struct fpc_zos_lrow { unsigned int off, line; };
struct fpc_zos_lfunc { const char *name, *file; const struct fpc_zos_lrow *rows; unsigned int n; };
struct fpc_zos_lfunc FPC_ZOS_LINETABLE[] = { { 0, 0, 0, 0 } };
