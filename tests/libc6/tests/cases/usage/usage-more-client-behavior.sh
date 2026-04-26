#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-coreutils-cut-fields)
    printf 'name:score\nalpha:42\nbeta:7\n' >"$tmpdir/in.txt"
    cut -d: -f2 "$tmpdir/in.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '42'
    validator_assert_contains "$tmpdir/out" '7'
    ;;
  usage-coreutils-wc-lines)
    printf 'alpha\nbeta\ngamma\n' >"$tmpdir/in.txt"
    wc -l "$tmpdir/in.txt" >"$tmpdir/out"
    grep -Eq '3[[:space:]]+' "$tmpdir/out"
    ;;
  usage-coreutils-join-files)
    printf '1 alpha\n2 beta\n' >"$tmpdir/left.txt"
    printf '1 one\n2 two\n' >"$tmpdir/right.txt"
    join "$tmpdir/left.txt" "$tmpdir/right.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '1 alpha one'
    validator_assert_contains "$tmpdir/out" '2 beta two'
    ;;
  usage-grep-word-match)
    printf 'alpha\nalphabet\nbeta alpha\n' >"$tmpdir/in.txt"
    grep -w 'alpha' "$tmpdir/in.txt" >"$tmpdir/out"
    grep -Fxq 'alpha' "$tmpdir/out"
    grep -Fxq 'beta alpha' "$tmpdir/out"
    ;;
  usage-gawk-number-format)
    printf '3.5\n4.5\n' >"$tmpdir/in.txt"
    gawk '{sum += $1} END {printf "sum=%.1f\n", sum}' "$tmpdir/in.txt" >"$tmpdir/out"
    grep -Fxq 'sum=8.0' "$tmpdir/out"
    ;;
  usage-sed-global-replace)
    printf 'alpha beta alpha\n' >"$tmpdir/in.txt"
    sed 's/alpha/omega/g' "$tmpdir/in.txt" >"$tmpdir/out"
    grep -Fxq 'omega beta omega' "$tmpdir/out"
    ;;
  usage-python3-json-roundtrip)
    python3 >"$tmpdir/out" <<'PY'
import ast
payload = {"name": "alpha", "count": 7, "items": [1, 2]}
text = repr(payload)
roundtrip = ast.literal_eval(text)
assert roundtrip["items"] == [1, 2]
print(text)
PY
    validator_assert_contains "$tmpdir/out" "'count': 7"
    validator_assert_contains "$tmpdir/out" "'name': 'alpha'"
    ;;
  usage-findutils-name-pattern)
    mkdir -p "$tmpdir/tree"
    : >"$tmpdir/tree/alpha.txt"
    : >"$tmpdir/tree/beta.log"
    find "$tmpdir/tree" -name '*.txt' | sort >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha.txt'
    if grep -Fq 'beta.log' "$tmpdir/out"; then
      printf 'find unexpectedly matched beta.log\n' >&2
      exit 1
    fi
    ;;
  usage-tar-append-archive)
    mkdir -p "$tmpdir/tree"
    printf 'alpha\n' >"$tmpdir/tree/alpha.txt"
    tar -cf "$tmpdir/archive.tar" -C "$tmpdir/tree" alpha.txt
    printf 'beta\n' >"$tmpdir/tree/beta.txt"
    tar -rf "$tmpdir/archive.tar" -C "$tmpdir/tree" beta.txt
    tar -tf "$tmpdir/archive.tar" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha.txt'
    validator_assert_contains "$tmpdir/out" 'beta.txt'
    ;;
  usage-gzip-stdout-roundtrip)
    printf 'stdout payload\n' >"$tmpdir/in.txt"
    gzip -c "$tmpdir/in.txt" >"$tmpdir/in.txt.gz"
    gzip -dc "$tmpdir/in.txt.gz" >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'stdout payload'
    ;;
  *)
    printf 'unknown libc6 additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
