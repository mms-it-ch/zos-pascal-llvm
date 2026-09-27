#!/bin/sh
# Baut den Cross-Compiler ppcs390x und die z/OS-RTL und installiert beides nach
# $PREFIX (Standard ~/opt/zfpc). In WSL ausführen.
#
#   build-rtl.sh [--no-compiler]
#
# Ergebnis:
#   $PREFIX/bin/ppcs390x, $PREFIX/bin/clang (-> zos-irc, llc), $PREFIX/bin/zos-ld
#   $PREFIX/units/zos/*.ppu, *.o (GOFF), zosmap.txt
set -e
REPO=$(cd "$(dirname "$0")/.." && pwd)
FPCSRC=${FPCSRC:-$HOME/src/fpc}
HOSTFPC=${HOSTFPC:-$HOME/opt/fpc-main/bin/ppcx64}
PREFIX=${PREFIX:-$HOME/opt/zfpc}
# C-Compiler für die Port-Laufzeit (runtime/*.c): clang mit z/OS-Korrekturen (~/build/llvm-zos);
# LLVM-IR -> GOFF übernimmt zos-irc (llc aus ~/build/llvm-pascal)
CLANG=${ZOS_CLANG:-$HOME/build/llvm-zos/bin/clang}
R=$FPCSRC/rtl
U=$PREFIX/units/zos

mkdir -p "$PREFIX/bin" "$U"
if [ "$1" != --no-compiler ]; then
  [ -d "$R/units/x86_64-linux" ] || make -C "$R" -j4 FPC="$HOSTFPC" >/dev/null
  rm -f "$FPCSRC/compiler/ppcs390x"
  make -C "$FPCSRC/compiler" -j4 LLVM=1 PPC_TARGET=s390x FPC="$HOSTFPC" >/dev/null
fi
cp "$FPCSRC/compiler/ppcs390x" "$PREFIX/bin/"
ln -sf "$REPO/scripts/zos-irc" "$PREFIX/bin/clang"
ln -sf "$REPO/scripts/zos-ld" "$PREFIX/bin/zos-ld"
python3 "$REPO/scripts/gen-zosmap.py" > "$U/zosmap.txt"

RO=$FPCSRC/packages/rtl-objpas/src/inc
RC=$FPCSRC/packages/rtl-console/src
PPC="$PREFIX/bin/ppcs390x -Tzos -Clv17.0 -n -FD$PREFIX/bin -FU$U -Fu$U -dFPC_USE_LIBC
  -Fi$R/zos -Fi$R/unix -Fi$R/inc -Fi$R/s390x -Fi$R/objpas -Fi$R/objpas/sysutils -Fi$R/objpas/classes
  -Fu$R/inc -Fu$R/unix -Fu$R/objpas -Fi$RO -Fu$RO -Fi$RC/inc -Fi$RC/unix -Fu$RC/unix $ZFPC_OPT"
rm -f "$U"/*.ppu "$U"/*.o.tmp

# C-Laufzeit des Ports (Unwind-Schnittstelle, atomare Operationen)
for f in zosunwind zosatomic zoscompat zosfpu zossig; do
  "$CLANG" --target=s390x-ibm-zos -O2 -trigraphs -mzos-sys-include="${ZOS_INCLUDE:-$HOME/zos/include}" \
    -D__CHARSET_LIB=1 -D_ALL_SOURCE -D_UNIX03_SOURCE -D_UNIX03_THREADS \
    -c "$REPO/runtime/$f.c" -o "$U/$f.o"
done

# Units in Abhängigkeitsreihenfolge; ppcs390x erzeugt LLVM-IR und ruft clang auf
cd "$R/zos"
$PPC -Us -Sg system.pp
# weitere Units; Abhängigkeiten übersetzt der Compiler selbst
FAILED=""
for u in objpas/objpas.pp inc/strings.pp unix/sysutils.pp objpas/math.pp \
         objpas/typinfo.pp objpas/types.pp unix/classes.pp objpas/fgl.pp \
         inc/getopts.pp unix/dos.pp "$RC/unix/crt.pp" inc/iso7185.pp inc/extpas.pp inc/macpas.pp \
         unix/cwstring.pp unix/cthreads.pp inc/lnfodwrf.pp \
         inc/heaptrc.pp inc/uuchar.pp inc/cmem.pp \
         "$RO/strutils.pp" "$RO/dateutils.pp" "$RO/variants.pp" "$RO/varutils.pp" \
         "$RO/fmtbcd.pp"; do
  case "$u" in /*) src=$u ;; *) src=$R/$u ;; esac
  $PPC -Sg "$src" || FAILED="$FAILED $(basename "$src")"
done
[ -n "$FAILED" ] && echo "FEHLGESCHLAGEN:$FAILED"
ls "$U" | sed 's/\..*//' | sort -u | tr '\n' ' '; echo
