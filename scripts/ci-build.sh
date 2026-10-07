#!/bin/sh
# ci-build.sh: lokaler Teil der CI (GitHub Actions, .github/workflows/ci.yml); läuft auch
# von Hand unter Linux x86_64 (oder WSL).
#
#   ci-build.sh [schritt...]      Standard: alle Schritte in dieser Reihenfolge
#
# Schritte:
#   source    FPC main klonen (Basis fpc/BASE), Patchserie fpc/patches mit git am anwenden
#             (prüft, dass sie sauber anwendbar ist)
#   compiler  nativen FPC main (ppcx64) mit dem Start-Compiler (FPC 3.2.2) bauen
#             ("make cycle"), damit den Cross-Compiler ppcs390x
#   rtl       RTL und Packages für z/OS bis zum Objekt (build-rtl.sh mit ZFPC_CI=1),
#             gescheiterte Package-Units mit ci/package-failures.txt vergleichen
#   pf        Testprogramme pf*/*.pas für z/OS übersetzen (ohne Binden: -Cn)
#   python    Python-Skripte übersetzen, Tests in tests/ (unittest)
#   x86       portable Units (CCSID, Dezimal) auf x86_64-linux übersetzen und testen
#
# Umgebung:
#   FPCSRC      FPC-Quellen (Standard ~/src/fpc; Arbeitszweig zos-ci)
#   BOOTFPC     Start-Compiler (Standard: ppcx64 aus FPC 3.2.2, apt fp-compiler-3.2.2)
#   ZOS_LLVM_BIN  llc/opt für LLVM-IR -> Objekt (Standard /usr/lib/llvm-18/bin). Ein
#               Distributions-llc schreibt kein brauchbares GOFF (nur Kopf/Ende) und stürzt
#               bei llvm.global_ctors für z/OS ab (Bibliotheken, "library"): solche
#               Programme werden dann übersprungen; mit dem eigenen LLVM-Zweig
#               (~/build/llvm-pascal/bin) ZOS_LLVM_FORK=1 setzen.
#   PREFIX      Installationsziel (Standard ~/opt/zfpc)
set -e
REPO=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
FPCSRC=${FPCSRC:-$HOME/src/fpc}
BOOTFPC=${BOOTFPC:-$(ls /usr/lib/x86_64-linux-gnu/fpc/3.2.2/ppcx64 2>/dev/null || command -v ppcx64)}
export ZOS_LLVM_BIN=${ZOS_LLVM_BIN:-/usr/lib/llvm-18/bin}
export PREFIX=${PREFIX:-$HOME/opt/zfpc}
export ZFPC_PREFIX=$PREFIX
HOSTDIR=${HOSTDIR:-$HOME/opt/fpc-main}
BASE=$(cat "$REPO/fpc/BASE")
STEPS=${*:-"source compiler rtl pf python x86"}
WORK=${CI_WORK:-${TMPDIR:-/tmp}/zpas-ci}
mkdir -p "$WORK"

step() { echo; echo "=== $* ($(date '+%H:%M:%S'))"; }

do_source() {
  step "FPC-Quellen: Basis $BASE, Patchserie"
  if [ ! -d "$FPCSRC/.git" ]; then
    git clone -q --filter=blob:none --no-checkout https://gitlab.com/freepascal.org/fpc/source.git "$FPCSRC"
  fi
  cd "$FPCSRC"
  git cat-file -e "$BASE^{commit}" 2>/dev/null || git fetch -q origin main
  git am --abort >/dev/null 2>&1 || true
  git checkout -q -f -B zos-ci "$BASE"
  git clean -q -fdx
  # Identität für git am (Autor kommt aus den Patches)
  GIT_COMMITTER_NAME=ci GIT_COMMITTER_EMAIL=ci@localhost \
    git am -q --whitespace=nowarn "$REPO"/fpc/patches/*.patch
  n=$(git rev-list --count "$BASE"..HEAD)
  echo "Patches angewendet: $n von $(ls "$REPO"/fpc/patches/*.patch | wc -l)"
}

do_compiler() {
  step "nativer FPC main (make cycle, Start-Compiler $BOOTFPC)"
  [ -x "$BOOTFPC" ] || { echo "Start-Compiler fehlt (apt install fp-compiler-3.2.2)"; exit 1; }
  cd "$FPCSRC"
  make -C compiler cycle FPC="$BOOTFPC" > "$WORK/cycle.log" 2>&1 ||
    { tail -30 "$WORK/cycle.log"; exit 1; }
  mkdir -p "$HOSTDIR/bin"
  cp compiler/ppcx64 "$HOSTDIR/bin/"
  "$HOSTDIR/bin/ppcx64" -iW
  step "Cross-Compiler ppcs390x"
  rm -f compiler/ppcs390x
  make -C compiler -j"$(nproc)" LLVM=1 PPC_TARGET=s390x FPC="$HOSTDIR/bin/ppcx64" > "$WORK/ppcs390x.log" 2>&1 ||
    { tail -30 "$WORK/ppcs390x.log"; exit 1; }
  echo "ppcs390x: $(compiler/ppcs390x -iWTPTO), z/OS-Port $(compiler/ppcs390x -iZ)"
  if [ "$(compiler/ppcs390x -iZ)" != "$(cat "$REPO/VERSION")" ]; then
    echo "FEHLER: Version des Compilers ($(compiler/ppcs390x -iZ)) passt nicht zu VERSION ($(cat "$REPO/VERSION"))"
    exit 1
  fi
}

do_rtl() {
  step "RTL und Packages für z/OS (llc: $ZOS_LLVM_BIN)"
  ZFPC_CI=1 HOSTFPC="$HOSTDIR/bin/ppcx64" FPCSRC="$FPCSRC" LOG="$WORK/packages.log" \
    ZFPC_PKG_FAILED="$WORK/package-failures.txt" \
    sh "$REPO/scripts/build-rtl.sh" > "$WORK/rtl.log" 2>&1 || { tail -30 "$WORK/rtl.log"; exit 1; }
  if grep -q '^FEHLGESCHLAGEN' "$WORK/rtl.log"; then
    grep '^FEHLGESCHLAGEN' "$WORK/rtl.log"; exit 1
  fi
  grep -E '^(Units übersetzt|2\. Durchgang)' "$WORK/rtl.log"
  grep -q '2. Durchgang (-B, ein Lauf): ok' "$WORK/rtl.log" || { echo "FEHLER: 2. Durchgang"; exit 1; }
  if ! grep -v '^#' "$REPO/ci/package-failures.txt" | diff -u - "$WORK/package-failures.txt"; then
    echo "FEHLER: gescheiterte Package-Units weichen von ci/package-failures.txt ab"
    exit 1
  fi
  echo "RTL-Units: $(ls "$PREFIX/units/zos"/*.ppu | wc -l) ppu"
}

do_pf() {
  step "Testprogramme pf*/ für z/OS übersetzen (ohne Binden)"
  out=$WORK/pf; rm -rf "$out"; mkdir -p "$out/u"
  ok=0; skip=0; fail=""
  for f in "$REPO"/pf[0-9]*/*.pas; do
    b=$(basename "$f" .pas)
    # Distributions-llc: Bibliotheken (llvm.global_ctors) gehen nicht
    if [ "$ZOS_LLVM_FORK" != 1 ] && head -c 2000 "$f" | grep -qiE '^[[:space:]]*library[[:space:]]'; then
      skip=$((skip+1)); continue
    fi
    if (cd "$(dirname "$f")" && sh "$REPO/scripts/zfpc" -Cn -FE"$out" -FU"$out/u" "$f") > "$out/$b.log" 2>&1; then
      ok=$((ok+1))
    else
      fail="$fail $f"; tail -5 "$out/$b.log"
    fi
  done
  echo "übersetzt: $ok, übersprungen (library, Distributions-llc): $skip"
  [ -z "$fail" ] || { echo "FEHLER:$fail"; exit 1; }
}

do_python() {
  step "Python-Skripte"
  python3 -m py_compile "$REPO"/scripts/*.py
  rm -rf "$REPO"/scripts/__pycache__
  if [ -d "$REPO/tests" ]; then
    (cd "$REPO" && python3 -m unittest discover -s tests -p 'test_*.py')
  fi
}

do_x86() {
  step "portable Units auf x86_64-linux"
  if [ -x "$REPO/tests/run-x86.sh" ]; then
    FPCSRC="$FPCSRC" HOSTFPC="$HOSTDIR/bin/ppcx64" WORK="$WORK/x86" sh "$REPO/tests/run-x86.sh"
  else
    echo "(keine)"
  fi
}

for s in $STEPS; do
  case "$s" in
    source|compiler|rtl|pf|python|x86) "do_$s" ;;
    *) echo "unbekannter Schritt: $s" >&2; exit 2 ;;
  esac
done
step "fertig"
