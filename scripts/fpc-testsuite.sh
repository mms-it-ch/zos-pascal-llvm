#!/bin/sh
# FPC-Testsuite (~/src/fpc/tests) für das Target zos: übersetzt jeden Test mit zfpc,
# bindet ihn auf z/OS (zos-ld, RTL als Archiv) und führt ihn dort aus (Start-Skript).
# In WSL ausführen. Voraussetzung: build-rtl.sh und zos-install-rtl.sh gelaufen.
#
#   fpc-testsuite.sh [-j N] [-n] verzeichnis...     (z.B. tbs test webtbs)
#     -j N  parallele Tests (Standard 6)
#     -n    nur Zusammenfassung der vorhandenen Logs
#     -r    nur die im vorhandenen Log gescheiterten Tests ("Failed ...") wiederholen
#     -c    abgebrochenen Lauf fortsetzen (erledigte Tests überspringen)
#
# Ergebnis: ~/src/fpc/tests/output/s390x-zos/log.<verzeichnis>log (eine Zeile je Test)
# Referenz für den Vergleich: native x86_64-linux (fpc-testsuite-ref.sh).
REPO=$(cd "$(dirname "$0")/.." && pwd)
T=${FPCTESTS:-$HOME/src/fpc/tests}
J=6; SUMMARY_ONLY=0; RETRY=0; CONTINUE=0
while [ $# -gt 0 ]; do
  case "$1" in
    -j) J=$2; shift 2 ;;
    -n) SUMMARY_ONLY=1; shift ;;
    -r) RETRY=1; shift ;;
    -c) CONTINUE=1; shift ;;
    *) break ;;
  esac
done
OUT=$T/output/s390x-zos
# Testprogramme nach dem Lauf auf z/OS löschen (Platz im Dateisystem)
export ZOS_RUN_ONCE=1
# Abstürze ohne LE-Traceback beenden. Achtung: ein Test, der den Stack zerstört, erzeugt
# trotzdem U4083 RSN F und ein Dump-Dataset unter der User-ID (MSG verhindert das nicht)
export ZOS_RUN_CEEOPTS=${ZOS_RUN_CEEOPTS:-TERMTHDACT(MSG)}
# Bibliotheks-Tests laden ./lib<name>.so aus dem Arbeitsverzeichnis
export ZOS_RUN_DLLS=1
cd "$T" || exit 1

if [ $SUMMARY_ONLY = 0 ]; then
  # Hilfs-Units der Testsuite
  mkdir -p tstunits/s390x-zos
  for u in erroru popuperr; do
    # neu übersetzen, wenn Quelle oder RTL (system.ppu) neuer ist
    [ tstunits/s390x-zos/$u.ppu -nt tstunits/$u.pp ] &&
      [ tstunits/s390x-zos/$u.ppu -nt "${PREFIX:-$HOME/opt/zfpc}/units/zos/system.ppu" ] ||
      sh "$REPO/scripts/zfpc" -FEtstunits/s390x-zos tstunits/$u.pp >/dev/null
  done
  # C-Objekte der C-ABI-Tests (test/cg/tcalext*, tcalpvr*: {$L ctest.o} usw.), wie
  # "make create_c_objects copyfiles", mit clang für z/OS
  CO=test/cg/obj/zos/s390x
  mkdir -p $CO "$OUT/test/cg"
  for c in ctest tcext3 tcext4 tcext5 tcext6 tcext7; do
    [ $CO/$c.o -nt test/cg/obj/$c.c ] ||
      "${ZOS_CLANG:-$HOME/build/llvm-zos/bin/clang}" --target=s390x-ibm-zos -O2 -trigraphs \
        -mzos-sys-include="$HOME/zos/include" -D__CHARSET_LIB=1 -fvisibility=default \
        -c test/cg/obj/$c.c -o $CO/$c.o
    cp $CO/$c.o "$OUT/test/cg/"
  done
  # C++-Objekte (test/cg/tcppcl*): nur Klassen ohne Bibliothek, wie "gcc -fno-exceptions"
  for c in cpptcl1 cpptcl2; do
    [ $CO/$c.o -nt test/cg/obj/$c.cpp ] ||
      "${ZOS_CLANGXX:-$HOME/build/llvm-zos/bin/clang++}" --target=s390x-ibm-zos -O2         -fno-exceptions -fvisibility=default -c test/cg/obj/$c.cpp -o $CO/$c.o
    cp $CO/$c.o "$OUT/test/cg/"
  done
  # Aufräumen auf z/OS: Programme von Tests, die nur übersetzt und nicht ausgeführt
  # werden, bleiben sonst liegen. Jede Minute alles löschen, was älter als der
  # vorige Durchgang ist (lib, bind, run bleiben).
  CLEAN="find . ! -name . -prune -type f ! -name .prev ! -newer .prev -exec rm -f {} \\; 2>/dev/null; touch .prev"
  ( sh "$REPO/scripts/zos-sh" "touch .prev" >/dev/null 2>&1
    while sleep 60; do sh "$REPO/scripts/zos-sh" "$CLEAN" >/dev/null 2>&1; done ) &
  CLEANER=$!
  trap 'kill $CLEANER 2>/dev/null' EXIT
  for d in "$@"; do
    # Logname: Unterverzeichnisse (test/cg) mit _ statt /
    dn=$(echo "$d" | tr / _)
    mkdir -p "$OUT/$d"
    L=$OUT/log.${dn}log
    if [ $RETRY = 1 ]; then
      # gescheiterte Tests aus dem Log nehmen und neu laufen lassen
      grep '^Failed' "$L" | grep -oE "$d/[^ ]*\.(pp|pas)" | sort -u > "$L.retry"
      grep -v -F -f "$L.retry" "$L" > "$L.keep"; mv "$L.keep" "$L"
      cat "$L.retry"
    elif [ $CONTINUE = 1 ]; then
      # abgebrochenen Lauf fortsetzen: Logs der dotest-Prozesse übernehmen; als
      # erledigt gilt ein Test mit einem Eintrag außer "Successfully compiled"
      # (ein Lauftest kann beim Abbruch nur übersetzt worden sein)
      for f in "$OUT"/log.[0-9]*; do
        [ -f "$f" ] && cat "$f" >> "$L" && rm -f "$f"
      done
      touch "$L"
      grep -v '^Successfully compiled' "$L" | grep -oE "$d/[^ ]*\.(pp|pas)" | sort -u > "$L.done"
      grep -F -f "$L.done" "$L" > "$L.keep"; mv "$L.keep" "$L"
      ls "$d"/*.pp "$d"/*.pas 2>/dev/null | grep -v -x -F -f "$L.done"
    else
      rm -f "$L" "$OUT/faillist.${dn}log" "$OUT/longlog.${dn}log"
      ls "$d"/*.pp "$d"/*.pas 2>/dev/null
    fi | sort |
      # -L: eigene Hilfsdateien je dotest-Prozess (sonst Wettlauf um out.);
      # ZOS_RUN_FILES: %FILES des Tests, das Startskript lädt sie auf z/OS hoch
      # (sh -c: $0 = dotest, $1 = zfpc, $2 = Test von xargs)
      xargs -P "$J" -n 1 sh -c 'ZOS_RUN_FILES=$(sed -n "s/.*{ *%FILES=\([^}]*\)}.*/\1/Ip" "$2" | head -1) exec "$0" -L -C"$1" -Tzos -E -Z "$2"' "$T/utils/dotest" "$REPO/scripts/zfpc"
    # dotest -L schreibt log.<pid>, faillist.<pid>, longlog.<pid> -> zusammenführen
    for k in log faillist longlog; do
      for f in "$OUT"/$k.[0-9]*; do
        [ -f "$f" ] && cat "$f" >> "$OUT/$k.${dn}log" && rm -f "$f"
      done
    done
  done
  kill $CLEANER 2>/dev/null
  # am Ende alle Testprogramme entfernen
  sh "$REPO/scripts/zos-sh" "find . ! -name . -prune -type f -exec rm -f {} \\;" >/dev/null 2>&1
fi

# Zusammenfassung (Kategorien wie im FPC-Makefile/digest)
for d in "$@"; do
  dn=$(echo "$d" | tr / _)
  L=$OUT/log.${dn}log
  [ -f "$L" ] || continue
  echo "== $d: $(wc -l < "$L") Einträge"
  sed -E 's/ [^ ]+\.(pp|pas) [0-9]{4}\/.*$//; s/ [^ ]+\.(pp|pas)$//' "$L" | sort | uniq -c | sort -rn
done
