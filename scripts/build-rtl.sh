#!/bin/sh
# Baut den Cross-Compiler ppcs390x und die z/OS-RTL und installiert beides nach
# $PREFIX (Standard ~/opt/zfpc). In WSL ausführen.
#
#   build-rtl.sh [--no-compiler]
#
# Ergebnis:
#   $PREFIX/bin/ppcs390x, $PREFIX/bin/clang (-> zos-irc, llc), $PREFIX/bin/zos-ld
#   $PREFIX/units/zos/*.ppu, *.o (GOFF), zosmap.txt
#
# ZFPC_CI=1 (GitHub Actions, ohne z/OS-Header und ohne den eigenen clang): die
# C-Laufzeit (runtime/*.c) und zosmap.txt entfallen (leere Tabelle: C-Namen bleiben
# ungemappt), es wird nur geprüft, dass sich Compiler, RTL und Packages übersetzen
# lassen; LLVM-IR -> Objekt mit dem llc aus ZOS_LLVM_BIN (auch ein Distributions-llc).
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
# ZFPC_DOTTED=1: Units mit Namensraum (System.SysUtils, System.Classes, UnixApi.Base, ...)
# nach units/zos-ns, wie der FPC-Bau mit FPC_DOTTEDUNITS (Hüllen aus rtl/namespaced);
# Programme wählen den Satz mit zfpc --ns. Beide Sätze nicht in einem Programm mischen.
NS=""
if [ "$ZFPC_DOTTED" = 1 ]; then
  U=$PREFIX/units/zos-ns
  NS="-dFPC_DOTTEDUNITS -Fu$R/namespaced/common -Fu$FPCSRC/packages/rtl-objpas/namespaced
    -Fu$FPCSRC/packages/rtl-console/namespaced"
fi

mkdir -p "$PREFIX/bin" "$U"
if [ "$1" != --no-compiler ]; then
  [ -d "$R/units/x86_64-linux" ] || make -C "$R" -j4 FPC="$HOSTFPC" >/dev/null
  rm -f "$FPCSRC/compiler/ppcs390x"
  make -C "$FPCSRC/compiler" -j4 LLVM=1 PPC_TARGET=s390x FPC="$HOSTFPC" >/dev/null
fi
cp "$FPCSRC/compiler/ppcs390x" "$PREFIX/bin/"
ln -sf "$REPO/scripts/zos-irc" "$PREFIX/bin/clang"
ln -sf "$REPO/scripts/zos-ld" "$PREFIX/bin/zos-ld"
if [ "$ZFPC_CI" = 1 ]; then
  : > "$U/zosmap.txt"
else
  python3 "$REPO/scripts/gen-zosmap.py" > "$U/zosmap.txt"
fi

RO=$FPCSRC/packages/rtl-objpas/src/inc
RC=$FPCSRC/packages/rtl-console/src
PPC="$PREFIX/bin/ppcs390x -Tzos -Clv17.0 -n -FD$PREFIX/bin -FU$U -Fu$U -dFPC_USE_LIBC
  -Fi$R/zos -Fi$R/unix -Fi$R/inc -Fi$R/s390x -Fi$R/objpas -Fi$R/objpas/sysutils -Fi$R/objpas/classes
  -Fu$R/inc -Fu$R/unix -Fu$R/objpas -Fi$RO -Fu$RO -Fi$RC/inc -Fi$RC/unix -Fu$RC/unix $NS $ZFPC_OPT"
rm -f "$U"/*.ppu "$U"/*.o.tmp

# C-Laufzeit des Ports (Unwind-Schnittstelle, atomare Operationen)
[ "$ZFPC_CI" = 1 ] ||
for f in zosunwind zosatomic zoscompat zosfpu zossig zosdsn zoslines0 zosdbg; do
  "$CLANG" --target=s390x-ibm-zos -O2 -trigraphs -mzos-sys-include="${ZOS_INCLUDE:-$HOME/zos/include}" \
    -D__CHARSET_LIB=1 -D_ALL_SOURCE -D_UNIX03_SOURCE -D_UNIX03_THREADS \
    -c "$REPO/runtime/$f.c" -o "$U/$f.o"
done

# Units in Abhängigkeitsreihenfolge; ppcs390x erzeugt LLVM-IR und ruft clang auf
cd "$R/zos"
$PPC -Us -Sg system.pp
# weitere Units; Abhängigkeiten übersetzt der Compiler selbst
FAILED=""
UNITS="objpas/objpas.pp inc/strings.pp unix/sysutils.pp objpas/math.pp
       objpas/typinfo.pp objpas/types.pp unix/classes.pp objpas/fgl.pp
       inc/getopts.pp unix/dos.pp $RC/unix/crt.pp inc/iso7185.pp inc/extpas.pp inc/macpas.pp
       unix/cwstring.pp unix/cthreads.pp inc/lnfodwrf.pp
       inc/heaptrc.pp inc/uuchar.pp inc/cmem.pp
       objpas/unicodedata.pas objpas/character.pas zos/zosebcdic.pp zos/zosrecio.pp
       $RO/strutils.pp $RO/dateutils.pp $RO/variants.pp $RO/varutils.pp
       $RO/fmtbcd.pp $RO/rtti.pp $RO/nullable.pp $RO/tuples.pp"
if [ "$ZFPC_DOTTED" = 1 ]; then
  # dieselben Units über ihre Hüllen; ohne Hülle (objpas, extpas, heaptrc, ...) unter dem
  # alten Namen, wie im FPC-Bau
  N=$R/namespaced/common
  NO=$FPCSRC/packages/rtl-objpas/namespaced
  UNITS="objpas/objpas.pp $N/System.Strings.pp $N/System.SysUtils.pp $N/System.Math.pp
         $N/System.TypInfo.pp $N/System.Types.pp $N/System.Classes.pp $N/System.FGL.pp
         $N/System.GetOpts.pp $N/TP.DOS.pp $FPCSRC/packages/rtl-console/namespaced/System.Console.Crt.pp
         inc/iso7185.pp inc/extpas.pp inc/macpas.pp
         $N/UnixApi.CWString.pp $N/UnixApi.CThreads.pp inc/lnfodwrf.pp
         inc/heaptrc.pp inc/uuchar.pp $N/System.CMem.pp
         $N/System.CodePages.unicodedata.pas $N/System.Character.pas zos/zosebcdic.pp zos/zosrecio.pp
         $NO/System.StrUtils.pp $NO/System.DateUtils.pp $NO/System.Variants.pp $NO/System.VarUtils.pp
         $NO/Data.FMTBcd.pp $NO/System.Rtti.pp $NO/System.Nullable.pp $NO/System.Tuples.pp"
fi
# Units des Ports aus diesem Repository (rtl/): CCSID-Tabellen, Dezimalzahlen
UNITS="$UNITS $REPO/rtl/zosccsid.pp $REPO/rtl/zosdecimal.pp $REPO/rtl/zosdecimalbcd.pp
       $REPO/rtl/zoscobol.pp $REPO/rtl/zosdb2cli.pp"
for u in $UNITS; do
  case "$u" in /*) src=$u ;; *) src=$R/$u ;; esac
  $PPC -Sg "$src" || FAILED="$FAILED $(basename "$src")"
done
[ -n "$FAILED" ] && echo "FEHLGESCHLAGEN:$FAILED"
ls "$U" | sed 's/\..*//' | sort -u | tr '\n' ' '; echo

# Packages (FCL u. a.) hängen an den Prüfsummen der RTL-Units: nach jedem RTL-Bau
# neu übersetzen (ZFPC_NO_PACKAGES=1: nicht)
[ -n "$ZFPC_NO_PACKAGES" ] || sh "$REPO/scripts/build-packages.sh"
