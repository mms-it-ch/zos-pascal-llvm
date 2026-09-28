# PF5: C-ABI für Records (XPLINK-64)

`abi.pas` + `abi_c.c`: Records als Ergebnis und als Wertparameter von `cdecl`-Funktionen, in
beide Richtungen (Pascal ruft C, C ruft Pascal). Ergebnis (28.09.2026): 27/27.

```sh
clang --target=s390x-ibm-zos -O1 -trigraphs -mzos-sys-include=$HOME/zos/include \
      -D__CHARSET_LIB=1 -c abi_c.c -o abi_c.o      # clang aus ~/build/llvm-zos
sh ../scripts/zfpc abi.pas && ./abi
```

## Regeln (wie clang, `ZOSXPLinkABIInfo`)

| Fall | Übergabe |
|---|---|
| Ergebnis ≤ 24 Byte | GPR 1–3, `inreg [n x i64]`, Daten linksbündig (auch 1–7, 12, 20 Byte, einzelnes float/double, `{float, double}`) |
| Ergebnis complex-artig (`{float, float}`, `{double, double}`) | FPR 0 und 2, normales Struct |
| Ergebnis > 24 Byte | versteckter Ergebniszeiger (`sret`) |
| Wertparameter | volle 64-Bit-Slots, Daten linksbündig (auch 1, 2, 4 Byte und der letzte Teil-Slot), auch > 24 Byte |
| Wertparameter complex-artig | zwei FPRs (bzw. Stack), GPR-Slots werden mitgezählt |

## Was vorher falsch war (FPC-Patch 0022)

- Ergebnisse: nur 8/16/24 Byte kamen in Registern, alle anderen Größen per `sret` (C gibt sie
  in GPRs zurück), complex-artige Records per `sret` statt in FPRs.
- Parameter: Records mit 1, 2, 4 Byte gingen als Ganzzahl eigener Größe (rechtsbündig); der
  letzte, teilweise gefüllte Slot größerer Records wurde als `i32` geladen und mit `zext`
  erweitert (generischer Code in `llvmgetcgparadef`, für Little-Endian gedacht);
  complex-artige Records gingen in GPRs.
- Dafür nötig im generischen Code: `gen_load_loc_cgpara` behandelte einen Record in mehreren
  FPU-Locations wie einen einzelnen Gleitkommawert (Internal Error 200408162); der
  LLVM-Codegenerator lädt/speichert jetzt FPU-Locations solcher Records.

## FPC-Testsuite

`test/cg/tcalext*`, `tcalpvr*` (C-Objekte `test/cg/obj/*.c`, von `fpc-testsuite.sh` mit clang
für z/OS übersetzt): 12/12. Diese Tests (und `test/cg` insgesamt) waren im PF3-Lauf nicht dabei,
weil nur die oberste Ebene von `test/` lief; `fpc-testsuite.sh test/cg` geht jetzt (Lognamen
mit `_` statt `/`).
