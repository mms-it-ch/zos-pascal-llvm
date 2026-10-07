#!/bin/sh
# ci-zos.sh: z/OS-Teil der CI (Self-Hosted-Runner): Testprogramme aus ci/zos-tests.txt
# übersetzen, auf z/OS binden (zos-ld) und ausführen; erwartet Returncode 0.
# Voraussetzung: build-rtl.sh (eigener LLVM-Zweig) und zos-install-rtl.sh gelaufen,
# Zugangsdaten in ZOS_ENV (aus den Secrets geschrieben, siehe .github/workflows/ci.yml).
# Ausgaben: $CI_WORK/zos/<name>.out; Host und User-ID werden maskiert.
REPO=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
WORK=${CI_WORK:-${TMPDIR:-/tmp}/zpas-ci}/zos
LIST=${1:-$REPO/ci/zos-tests.txt}
CLANG=${ZOS_CLANG:-$HOME/build/llvm-zos/bin/clang}
mkdir -p "$WORK"
MASK='s|/u/[A-Za-z0-9]+/|/u/<u>/|g; s|[A-Za-z0-9._-]+@[A-Za-z0-9._-]+|<user@host>|g'
fail=0; n=0
while read -r prog args; do
  case "$prog" in ''|'#'*) continue ;; esac
  n=$((n+1))
  src=$REPO/$prog; dir=$(dirname "$src"); b=$(basename "$src" .pas)
  d=$WORK/$b; rm -rf "$d"; mkdir -p "$d"
  # C-Teil (pf5/abi.pas: {$L abi_c.o})
  if [ -f "$dir/${b}_c.c" ]; then
    "$CLANG" --target=s390x-ibm-zos -O2 -trigraphs -mzos-sys-include="${ZOS_INCLUDE:-$HOME/zos/include}" \
      -D__CHARSET_LIB=1 -fvisibility=default -c "$dir/${b}_c.c" -o "$d/${b}_c.o" || { fail=$((fail+1)); continue; }
  fi
  if ! (cd "$dir" && sh "$REPO/scripts/zfpc" -O2 -FE"$d" -FU"$d" -Fo"$d" "$src") > "$d/compile.log" 2>&1; then
    echo "FEHLER (übersetzen/binden): $prog"; sed -E "$MASK" "$d/compile.log" | tail -15
    fail=$((fail+1)); continue
  fi
  # shellcheck disable=SC2086
  "$d/$b" $args > "$WORK/$b.out" 2>&1
  rc=$?
  sed -i -E "$MASK" "$WORK/$b.out"
  if [ $rc = 0 ]; then
    echo "ok     $prog ($(grep -c '^OK' "$WORK/$b.out") OK-Zeilen)"
  else
    echo "FEHLER $prog: rc $rc"; tail -20 "$WORK/$b.out"
    fail=$((fail+1))
  fi
done < "$LIST"
echo "z/OS: $((n-fail))/$n Programme ok"
[ $fail = 0 ]
