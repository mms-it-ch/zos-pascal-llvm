#!/bin/sh
# Baut FPC-Packages (FCL u. a.) für z/OS nach $PREFIX/units/zos (neben die RTL; das
# Archiv libfpc.a enthält sie nach zos-install-rtl.sh, ld nimmt nur benötigte Member).
# In WSL ausführen, nach build-rtl.sh.
#
#   build-packages.sh [package...]      Standard: siehe PKGS
#
# Die fpmake.pp der Packages kennen z/OS nicht; übersetzt wird jede Unit aus src/
# (und src/unix, wo vorhanden) mit den Suchpfaden aller Packages. Units, die ein anderes
# Betriebssystem voraussetzen, scheitern; die Liste steht am Ende (Log: $LOG).
REPO=$(cd "$(dirname "$0")/.." && pwd)
FPCSRC=${FPCSRC:-$HOME/src/fpc}
PREFIX=${PREFIX:-$HOME/opt/zfpc}
U=$PREFIX/units/zos
P=$FPCSRC/packages
LOG=${LOG:-$HOME/build-packages.log}
PKGS=${*:-"rtl-extra pthreads rtl-generics hash paszlib fcl-base fcl-json fcl-xml fcl-process
  fcl-registry fcl-fpcunit fcl-passrc fcl-stl fcl-res fcl-async fcl-net fcl-extra"}

# Suchpfade: alle Packages (src, src/inc, src/unix)
SP=""
for p in $PKGS; do
  for d in src src/inc src/unix src/zos; do
    [ -d "$P/$p/$d" ] && SP="$SP -Fu$P/$p/$d -Fi$P/$p/$d"
  done
done
# rtl/zos: pthread.inc für die Unit pthreads
PPC="$PREFIX/bin/ppcs390x -Tzos -Clv17.0 -n -FD$PREFIX/bin -FU$U -Fu$U $SP -Fi$FPCSRC/rtl/zos $ZFPC_OPT"

: > "$LOG"
# 1. Durchgang: jede Unit einzeln - welche lassen sich für z/OS übersetzen?
# 2. Durchgang: eine Hilfs-Unit, die alle erfolgreichen Units benutzt, mit -B in EINEM
#    Compiler-Lauf. Sonst übersetzt der Compiler Abhängigkeiten mehrfach, ihre
#    Prüfsummen ändern sich, und Units, die sie benutzen, passen nicht mehr
#    ("checksum changed", z. B. generics.collections/generics.defaults).
ok=0; failed=""; units=""
for p in $PKGS; do
  for d in src src/unix; do
    for f in "$P/$p/$d"/*.pp "$P/$p/$d"/*.pas; do
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
