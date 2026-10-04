#!/bin/sh
# run-x86.sh: portable Teile des Ports auf x86_64-linux testen (CI-Schritt "x86" von
# scripts/ci-build.sh, auch von Hand):
#   - runtime/zosdsn.c (CCSID-Logik) mit Attrappen der z/OS-Header (tests/c/stub), gcc
#   - Units aus rtl/ mit dem nativen FPC main und die portablen Testprogramme aus pf8/
#     (ci/x86-tests.txt; Returncode = Zahl der Fehler); zosdb2cli über unixODBC gegen
#     SQLite (Pakete unixodbc-dev, libsqliteodbc)
# Umgebung: FPCSRC (~/src/fpc), HOSTFPC (~/opt/fpc-main/bin/ppcx64), WORK (Arbeitsverzeichnis)
set -e
REPO=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
FPCSRC=${FPCSRC:-$HOME/src/fpc}
HOSTFPC=${HOSTFPC:-$HOME/opt/fpc-main/bin/ppcx64}
WORK=${WORK:-${TMPDIR:-/tmp}/zpas-x86}
CC=${CC:-cc}
rm -rf "$WORK"; mkdir -p "$WORK/u"
fail=0

echo "-- runtime/zosdsn.c (Attrappen)"
$CC -O1 -Wall -Wextra -Wno-unused-parameter -D_GNU_SOURCE -I"$REPO/tests/c/stub" \
  -include "$REPO/tests/c/stub/zosstdio.h" -o "$WORK/test_zosdsn" \
  "$REPO/tests/c/test_zosdsn.c" "$REPO/runtime/zosdsn.c"
( cd "$WORK" && ./test_zosdsn && ZOS_CCSID=IBM-1141 ./test_zosdsn 1141 ) || fail=1

# C-Laufzeit für die Units (zoscall31 bindet zosc31.o und zosdsn.o) und die Attrappe
# der AMODE-31-Brücke (pf8/call31test)
$CC -O1 -Wall -D_GNU_SOURCE -I"$REPO/tests/c/stub" -include "$REPO/tests/c/stub/zosstdio.h" \
  -c "$REPO/runtime/zosdsn.c" -o "$WORK/u/zosdsn.o"
$CC -O1 -Wall -c "$REPO/runtime/zosc31.c" -o "$WORK/u/zosc31.o"
$CC -O1 -Wall -o "$WORK/fake_zpcall31" "$REPO/tests/c/fake_zpcall31.c"
export ZOS_CALL31_BRIDGE=$WORK/fake_zpcall31

echo "-- Pascal-Units und pf8-Tests"
RO=$FPCSRC/packages/rtl-objpas/src/inc
PPC="$HOSTFPC -n -Fu$FPCSRC/rtl/units/x86_64-linux -Fu$RO -Fi$RO -Fu$REPO/rtl -Fu$REPO/pf8 -Fl$WORK/u -FU$WORK/u -FE$WORK"
# Zeilen "x86 <programm> [argumente]"; "x86odbc ...": nur mit unixODBC + SQLite-Treiber
sed -n 's/^\(x86\|x86odbc\) //p' "$REPO/ci/x86-tests.txt" > "$WORK/list"
while read -r t args; do
  b=$(basename "$t" .pas)
  if grep -q "^x86odbc $t" "$REPO/ci/x86-tests.txt" && ! odbcinst -q -d 2>/dev/null | grep -q '^\[SQLite3\]'; then
    echo "--     $t übersprungen (unixODBC/SQLite-ODBC fehlt: apt install unixodbc-dev libsqliteodbc)"
    continue
  fi
  if ! $PPC "$REPO/$t" > "$WORK/$b.log" 2>&1; then
    echo "FEHLER (übersetzen): $t"; tail -10 "$WORK/$b.log"; fail=1; continue
  fi
  # shellcheck disable=SC2086
  if (cd "$WORK" && eval "./$b $args" > "$b.out" 2>&1); then
    echo "ok     $t: $(tail -1 "$WORK/$b.out")"
  else
    echo "FEHLER $t:"; grep -v '^OK' "$WORK/$b.out" | tail -20; fail=1
  fi
done < "$WORK/list"
exit $fail
