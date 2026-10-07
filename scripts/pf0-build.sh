#!/bin/sh
# PF0: Cross-Compiler ppcs390x bauen und das Testprogramm pf0/minrtl bis zu
# GOFF-Objekten übersetzen (in WSL ausführen).
#
# Voraussetzungen (siehe README.md):
#   ~/opt/fpc-main/bin/ppcx64   nativer FPC-main-Compiler (Bootstrap aus FPC 3.2.2)
#   ~/src/fpc                   FPC-Quellen, Zweig zos = Basis + fpc/patches/*
#   ~/build/llvm-zos/bin/clang  clang mit z/OS-Korrekturen (LLVM 23.1.2)
#
# Ergebnis: ~/build/pf0/minrtl/{system,hello}.o
# Ausführen auf z/OS: Objekte mit scripts/zos-ld binden (Bindeliste, siehe dort)
set -e
REPO=$(cd "$(dirname "$0")/.." && pwd)
FPCSRC=${FPCSRC:-$HOME/src/fpc}
HOSTFPC=${HOSTFPC:-$HOME/opt/fpc-main/bin/ppcx64}
CLANG=${ZOS_CLANG:-$HOME/build/llvm-zos/bin/clang}
OUT=$HOME/build/pf0/minrtl

# Host-RTL (für den Compiler-Build) und Cross-Compiler
[ -d "$FPCSRC/rtl/units/x86_64-linux" ] || make -C "$FPCSRC/rtl" -j4 FPC="$HOSTFPC" >/dev/null
rm -f "$FPCSRC/compiler/ppcs390x"
make -C "$FPCSRC/compiler" -j4 LLVM=1 PPC_TARGET=s390x FPC="$HOSTFPC" >/dev/null
PPC=$FPCSRC/compiler/ppcs390x

# Minimal-RTL + Programm -> LLVM-IR -> GOFF
mkdir -p "$OUT"
cp "$REPO"/pf0/minrtl/system.pp "$REPO"/pf0/minrtl/hello.pas "$OUT"/
cd "$OUT"
rm -f ./*.ppu ./*.ll ./*.o
"$PPC" -n -Us -Clv17.0 -a -s system.pp >/dev/null
"$PPC" -n -Clv17.0 -Fu. -a -s hello.pas >/dev/null
for f in system hello; do
  "$CLANG" --target=s390x-ibm-zos -O2 -c -x ir $f.ll -o $f.o
done
ls -l "$OUT"/*.o
