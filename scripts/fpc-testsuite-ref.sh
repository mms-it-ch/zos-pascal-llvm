#!/bin/sh
# Referenzlauf der FPC-Testsuite nativ auf x86_64-linux (derselbe FPC-Stand, nativer
# Codegenerator), zum Vergleich mit fpc-testsuite.sh (z/OS). In WSL ausführen.
#   fpc-testsuite-ref.sh [-j N] verzeichnis...
# Ergebnis: ~/src/fpc/tests/output/x86_64-linux/log.<verzeichnis>log
T=${FPCTESTS:-$HOME/src/fpc/tests}
J=8
[ "$1" = -j ] && { J=$2; shift 2; }
FPCSRC=$(cd "$T/.." && pwd)
W=$HOME/opt/fpc-main/bin/fpcref
# Units aus rtl-objpas und rtl-console vorab übersetzen; der Compiler-Aufruf der Tests
# darf kein -FU enthalten (sonst landen die .ppu von Unit-Tests nicht im
# Ausgabeverzeichnis und dotest versucht, sie auszuführen: Exitcode 2000)
RO=$FPCSRC/packages/rtl-objpas/src
RC=$FPCSRC/packages/rtl-console/src
UX=$HOME/opt/fpc-main/units/rtlobjpas
mkdir -p "$UX"
for u in "$RO/inc/strutils.pp" "$RO/inc/dateutils.pp" "$RO/inc/variants.pp" \
         "$RO/inc/varutils.pp" "$RO/inc/fmtbcd.pp" "$RC/unix/crt.pp"; do
  "$HOME/opt/fpc-main/bin/ppcx64" -n -Fu"$HOME/opt/fpc-main/units/rtl" -Fu"$RO/inc" -Fi"$RO/inc" \
    -Fu"$RC/unix" -Fi"$RC/unix" -Fi"$RC/inc" -FU"$UX" "$u" >/dev/null ||
    echo "Referenz: $u fehlgeschlagen"
done
cat > "$W" <<EOW
#!/bin/sh
exec $HOME/opt/fpc-main/bin/ppcx64 -n -Fu$HOME/opt/fpc-main/units/rtl -Fu$UX "\$@"
EOW
chmod +x "$W"
OUT=$T/output/x86_64-linux
cd "$T" || exit 1
mkdir -p tstunits/x86_64-linux
for u in erroru popuperr; do
  "$W" -FEtstunits/x86_64-linux tstunits/$u.pp >/dev/null
done
# C-Objekte der C-ABI-Tests (test/cg), wie "make copyfiles"
mkdir -p "$OUT/test/cg"
cp test/cg/obj/linux/x86_64/*.o "$OUT/test/cg/" 2>/dev/null
for d in "$@"; do
  # Logname: Unterverzeichnisse (test/cg) mit _ statt /
  dn=$(echo "$d" | tr / _)
  mkdir -p "$OUT/$d"
  rm -f "$OUT/log.${dn}log" "$OUT/faillist.${dn}log" "$OUT/longlog.${dn}log"
  # -L: eigene Hilfs- und Logdateien je dotest-Prozess (sonst Wettlauf)
  ls "$d"/*.pp "$d"/*.pas 2>/dev/null | sort |
    xargs -P "$J" -n 1 "$T/utils/dotest" -L -C"$W" -Tlinux -E -Z
  for k in log faillist longlog; do
    for f in "$OUT"/$k.[0-9]*; do
      [ -f "$f" ] && cat "$f" >> "$OUT/$k.${dn}log" && rm -f "$f"
    done
  done
  echo "== $d: $(wc -l < "$OUT/log.${dn}log") Einträge"
done
