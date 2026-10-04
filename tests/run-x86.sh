#!/bin/sh
# run-x86.sh: portable Teile des Ports auf x86_64-linux testen (CI-Schritt "x86" von
# scripts/ci-build.sh, auch von Hand):
#   - runtime/zosdsn.c (CCSID-Logik) mit Attrappen der z/OS-Header (tests/c/stub), gcc
#   - Units rtl/zosccsid, zosdecimal, zosdecimalbcd mit dem nativen FPC main und die
#     portablen Testprogramme aus pf8/ (Returncode = Zahl der Fehler)
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

echo "-- Pascal-Units und pf8-Tests"
RO=$FPCSRC/packages/rtl-objpas/src/inc
PPC="$HOSTFPC -n -Fu$FPCSRC/rtl/units/x86_64-linux -Fu$RO -Fi$RO -Fu$REPO/rtl -Fu$REPO/pf8 -FU$WORK/u -FE$WORK"
for t in $(sed -n 's/^x86 //p' "$REPO/ci/x86-tests.txt"); do
  b=$(basename "$t" .pas)
  if ! $PPC "$REPO/$t" > "$WORK/$b.log" 2>&1; then
    echo "FEHLER (übersetzen): $t"; tail -10 "$WORK/$b.log"; fail=1; continue
  fi
  if (cd "$WORK" && "./$b" > "$b.out" 2>&1); then
    echo "ok     $t: $(tail -1 "$WORK/$b.out")"
  else
    echo "FEHLER $t:"; grep -v '^OK' "$WORK/$b.out" | tail -20; fail=1
  fi
done
exit $fail
