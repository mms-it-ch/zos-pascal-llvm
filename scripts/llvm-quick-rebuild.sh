#!/bin/sh
# Schnell-Neubau von llc in ~/build/llvm-quick (Kopie von
# ~/build/llvm-zos) für einzelne geänderte Quellen aus ~/src/llvm-pascal.
#   llvm-quick-rebuild.sh llvm/lib/MC/MCContext.cpp [...]
# Nur für Quellen ohne Header-Änderungen; der vollständige Build
# (~/build/llvm-pascal) ersetzt das später.
set -e
export PATH=$HOME/opt/bt/bin:$PATH
Q=$HOME/build/llvm-quick
SRC_OLD=$HOME/src/llvm-project
SRC_NEW=$HOME/src/llvm-pascal
cd "$Q"
[ -f cmds.txt ] || ninja -t commands bin/llc > cmds.txt
for f in "$@"; do
  line=$(grep -n " $SRC_OLD/$f\$\| $SRC_OLD/$f " cmds.txt | head -1 | cut -d: -f1)
  [ -n "$line" ] || { echo "keine Übersetzungsregel für $f" >&2; exit 1; }
  sed -n "${line}p" cmds.txt | sed "s| $SRC_OLD/$f| $SRC_NEW/$f|" | sh
  obj=$(sed -n "${line}p" cmds.txt | sed 's/.* -o \([^ ]*\) .*/\1/')
  # Archiv, das dieses Objekt enthält, neu erzeugen
  grep -n "llvm-ar .*$obj" cmds.txt | cut -d: -f2- | sh
done
tail -1 cmds.txt | sh
ls -l bin/llc
