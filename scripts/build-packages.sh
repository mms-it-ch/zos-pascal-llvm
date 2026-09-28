#!/bin/sh
# Baut FPC-Packages (FCL u. a.) für z/OS nach $PREFIX/units/zos (neben die RTL; das
# Archiv libfpc.a enthält sie nach zos-install-rtl.sh, ld nimmt nur benötigte Member).
# In WSL ausführen, nach build-rtl.sh.
#
#   build-packages.sh [package...]      Standard: siehe PKGS
#   ZFPC_PKG_TARGET=x86_64-linux build-packages.sh
#                                       dieselben Packages für Linux x86_64 (lokales Debuggen
#                                       mit gdb in der VS-Code-Erweiterung), mit dem Compiler
#                                       aus ~/opt/fpc-main gegen dessen RTL, nach
#                                       ~/opt/fpc-main/units/packages
#
# Die fpmake.pp der Packages kennen z/OS nicht; übersetzt wird jede Unit aus src/
# (und src/unix, wo vorhanden) mit den Suchpfaden aller Packages. Units, die ein anderes
# Betriebssystem voraussetzen, scheitern; die Liste steht am Ende (Log: $LOG).
REPO=$(cd "$(dirname "$0")/.." && pwd)
FPCSRC=${FPCSRC:-$HOME/src/fpc}
PREFIX=${PREFIX:-$HOME/opt/zfpc}
TARGET=${ZFPC_PKG_TARGET:-zos}
if [ "$TARGET" = zos ]; then
  U=$PREFIX/units/zos
  OSDIR=zos
else
  HOSTFPC=${HOSTFPC:-$HOME/opt/fpc-main}
  U=${ZFPC_PKG_UNITS:-$HOSTFPC/units/packages}
  OSDIR=linux
  mkdir -p "$U"
fi
P=$FPCSRC/packages
LOG=${LOG:-$HOME/build-packages.log}
PKGS=${*:-"rtl-extra pthreads rtl-generics hash paszlib fcl-base fcl-json fcl-xml fcl-process
  fcl-registry fcl-fpcunit fcl-passrc fcl-stl fcl-res fcl-async fcl-net fcl-extra
  fcl-hash fastcgi fcl-db/src/dbase fcl-db/src/base fcl-db/src/sqldb
  fcl-web/src/base fcl-web/src/jsonrpc fcl-web/src/jwt fcl-web/src/websocket
  fcl-web/src/restbridge"}
# Einträge mit /src/ sind einzelne Quellverzeichnisse eines Packages (fcl-web)
dirs_of() {
  case "$1" in
    */src/*) echo "$1" ;;
    *) echo "$1/src $1/src/inc $1/src/unix $1/src/$OSDIR" ;;
  esac
}

# Suchpfade: alle Packages (src, src/inc, src/unix)
SP=""
for p in $PKGS; do
  for d in $(dirs_of "$p"); do
    [ -d "$P/$d" ] && SP="$SP -Fu$P/$d -Fi$P/$d"
  done
done
# rtl/zos: pthread.inc für die Unit pthreads
if [ "$TARGET" = zos ]; then
  PPC="$PREFIX/bin/ppcs390x -Tzos -Clv17.0 -n -FD$PREFIX/bin -FU$U -Fu$U $SP -Fi$FPCSRC/rtl/zos $ZFPC_OPT"
else
  # mit Debug-Informationen (gdb); rtl/linux: pthread.inc für die Unit pthreads
  PPC="$HOSTFPC/bin/ppcx64 -n -g -gw3 -FU$U -Fu$U -Fu$HOSTFPC/units/rtl -Fu$HOSTFPC/units/rtlobjpas $SP -Fi$FPCSRC/rtl/linux -Fi$FPCSRC/rtl/unix $ZFPC_OPT"
fi

: > "$LOG"
# x86_64: Units aus rtl-objpas, die der Host-RTL fehlen (rtti, nullable, tuples, ...), vorab ins
# Package-Verzeichnis; vorhandene nicht neu übersetzen (sonst passen die Prüfsummen nicht mehr)
if [ "$TARGET" != zos ]; then
  RO=$FPCSRC/packages/rtl-objpas/src/inc
  for f in "$RO"/*.pp; do
    b=$(basename "$f" .pp | tr A-Z a-z)
    head -c 3000 "$f" | grep -qiE '^[[:space:]]*unit[[:space:]]' || continue
    [ -f "$HOSTFPC/units/rtlobjpas/$b.ppu" ] && continue
    (cd "$RO" && $PPC -Fi"$RO" "$f") >> "$LOG" 2>&1 || echo "rtl-objpas: $b gescheitert"
  done
fi
# 1. Durchgang: jede Unit einzeln - welche lassen sich für z/OS übersetzen?
# 2. Durchgang: eine Hilfs-Unit, die alle erfolgreichen Units benutzt, mit -B in EINEM
#    Compiler-Lauf. Sonst übersetzt der Compiler Abhängigkeiten mehrfach, ihre
#    Prüfsummen ändern sich, und Units, die sie benutzen, passen nicht mehr
#    ("checksum changed", z. B. generics.collections/generics.defaults).
ok=0; failed=""; units=""
for p in $PKGS; do
  case "$p" in */src/*) srcdirs="$p" ;; *) srcdirs="$p/src $p/src/inc $p/src/unix" ;; esac
  for d in $srcdirs; do
    for f in "$P/$d"/*.pp "$P/$d"/*.pas; do
      [ -f "$f" ] || continue
      # Programme (keine Units) überspringen
      head -c 4000 "$f" | grep -qiE '^[[:space:]]*(unit|library)[[:space:]]' || continue
      if (cd "$(dirname "$f")" && $PPC "$f") >> "$LOG" 2>&1; then
        ok=$((ok+1))
        units="$units $(basename "$f" | sed 's/\.[^.]*$//')"
      else
        failed="$failed $p/$(basename "$f")"
      fi
    done
  done
done
echo "Units übersetzt: $ok"
echo "gescheitert:$failed" | fold -w 100

T=$(mktemp -d)
{
  echo "unit zospkgall;"
  echo "{ erzeugt von build-packages.sh: alle für z/OS übersetzbaren Package-Units }"
  echo "interface"
  echo "uses"
  printf '%s\n' $units | sed 's/^/  /; $!s/$/,/; $s/$/;/'
  echo "implementation"
  echo "end."
} > "$T/zospkgall.pp"
if (cd "$T" && $PPC -B zospkgall.pp) >> "$LOG" 2>&1; then
  echo "2. Durchgang (-B, ein Lauf): ok"
else
  echo "2. Durchgang (-B, ein Lauf): FEHLER, siehe $LOG"
fi
rm -f "$U"/zospkgall.*
rm -rf "$T"
