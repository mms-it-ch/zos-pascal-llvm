#!/bin/sh
# Reproduzierer mit dem LLVM-Codegenerator von FPC auf x86_64-linux übersetzen und
# ausführen (in WSL):   run-x64.sh <FPC-Baum mit compiler/ppcx64 und rtl/units> test.pp...
# Ausgabe je Test: Exitcode oder Übersetzungsfehler.
# Hinweise zur Umgebung: libgcc_s.so (nur Laufzeitpaket) als Verknüpfung in ~/opt/linklibs;
# FPC hängt beim LLVM-Codegenerator --eh-frame-hdr an, womit ld.bfd hier an
# "overlapping FDEs" scheitert -> Option im Bindeskript entfernt (hat mit den Fehlern
# nichts zu tun).
L=$1; shift
export PATH=$HOME/llvm-23/bin:$PATH
W=$(mktemp -d)
T=${FPCTESTS:-$HOME/src/fpc/tests}
for f in "$@"; do
  b=$(basename "$f" .pp)
  rm -f "$W/ppas.sh" "$W"/link*.res
  "$L/compiler/ppcx64" -n -Cn -Fu"$L/rtl/units/x86_64-linux" -Fl"$HOME/opt/linklibs" \
    -Fu"$T/tstunits/x86_64-linux" -FE"$W" "$f" > "$W/$b.log" 2>&1
  c=$?
  if [ -f "$W/ppas.sh" ]; then
    sed -i 's/ --eh-frame-hdr$//' "$W/ppas.sh"
    (cd "$W" && sh ppas.sh) >> "$W/$b.log" 2>&1
  fi
  if [ -x "$W/$b" ]; then
    timeout 20 "$W/$b" > "$W/$b.out" 2>&1
    echo "$b: rc=$?"
  else
    echo "$b: nicht übersetzt/gebunden (rc=$c): $(grep -iE 'error|undefined' "$W/$b.log" | head -1 | cut -c1-100)"
  fi
done
rm -rf "$W"
