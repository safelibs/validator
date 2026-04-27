#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-bash-printf-hex-format)
    printf '%x\n' 255 >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'ff'
    ;;
  usage-coreutils-tr-delete-digits)
    printf 'abc123def456\n' >"$tmpdir/in.txt"
    tr -d '0-9' <"$tmpdir/in.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'abcdef'
    ;;
  usage-coreutils-od-hex-bytes)
    printf 'AB' >"$tmpdir/in.bin"
    od -An -tx1 "$tmpdir/in.bin" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '41 42'
    ;;
  usage-grep-only-matching)
    printf 'alpha=1\nbeta=2\n' >"$tmpdir/in.txt"
    grep -o '[a-z]\+' "$tmpdir/in.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha'
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-gawk-printf-precision)
    gawk 'BEGIN { printf "%.3f\n", 1.0/3 }' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '0.333'
    ;;
  usage-sed-print-line-range)
    cat >"$tmpdir/in.txt" <<'EOF'
one
two
three
four
EOF
    sed -n '2,3p' "$tmpdir/in.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'two'
    validator_assert_contains "$tmpdir/out" 'three'
    ;;
  usage-python3-os-listdir-sorted)
    mkdir -p "$tmpdir/lst"
    : >"$tmpdir/lst/alpha.txt"
    : >"$tmpdir/lst/beta.txt"
    DIR_PATH="$tmpdir/lst" python3 >"$tmpdir/out" <<'PY'
import os
print(','.join(sorted(os.listdir(os.environ['DIR_PATH']))))
PY
    validator_assert_contains "$tmpdir/out" 'alpha.txt,beta.txt'
    ;;
  usage-findutils-print-newer)
    mkdir -p "$tmpdir/tree"
    : >"$tmpdir/tree/old.txt"
    sleep 1
    touch "$tmpdir/marker"
    sleep 1
    : >"$tmpdir/tree/new.txt"
    find "$tmpdir/tree" -type f -newer "$tmpdir/marker" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'new.txt'
    ;;
  usage-tar-extract-single-member)
    mkdir -p "$tmpdir/src"
    printf 'alpha body\n' >"$tmpdir/src/alpha.txt"
    printf 'beta body\n' >"$tmpdir/src/beta.txt"
    tar -cf "$tmpdir/archive.tar" -C "$tmpdir/src" .
    mkdir -p "$tmpdir/dest"
    tar -xf "$tmpdir/archive.tar" -C "$tmpdir/dest" ./alpha.txt
    validator_assert_contains "$tmpdir/dest/alpha.txt" 'alpha body'
    test ! -e "$tmpdir/dest/beta.txt"
    ;;
  usage-gzip-keep-original)
    printf 'gzip keep payload\n' >"$tmpdir/in.txt"
    gzip -k "$tmpdir/in.txt"
    test -f "$tmpdir/in.txt"
    test -f "$tmpdir/in.txt.gz"
    gunzip -c "$tmpdir/in.txt.gz" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'gzip keep payload'
    ;;
  *)
    printf 'unknown libc6 tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
