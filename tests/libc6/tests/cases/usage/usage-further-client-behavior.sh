#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-bash-case-switch)
    bash >"$tmpdir/out" <<'BASH'
value=beta
case "$value" in
  alpha) echo no ;;
  beta) echo matched-beta ;;
  *) echo no ;;
esac
BASH
    validator_assert_contains "$tmpdir/out" 'matched-beta'
    ;;
  usage-coreutils-head-lines)
    printf 'one\ntwo\nthree\n' >"$tmpdir/in.txt"
    head -n 2 "$tmpdir/in.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'one'
    validator_assert_contains "$tmpdir/out" 'two'
    ;;
  usage-coreutils-tail-lines)
    printf 'one\ntwo\nthree\n' >"$tmpdir/in.txt"
    tail -n 1 "$tmpdir/in.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'three'
    ;;
  usage-coreutils-nl-lines)
    printf 'alpha\nbeta\n' >"$tmpdir/in.txt"
    nl -ba "$tmpdir/in.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '1'
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-grep-fixed-string)
    printf 'alpha[1]\nbeta\n' >"$tmpdir/in.txt"
    grep -F 'alpha[1]' "$tmpdir/in.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha[1]'
    ;;
  usage-gawk-string-upper)
    printf 'alpha\n' >"$tmpdir/in.txt"
    gawk '{print toupper($1)}' "$tmpdir/in.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'ALPHA'
    ;;
  usage-sed-insert-line)
    printf 'alpha\ngamma\n' >"$tmpdir/in.txt"
    sed '2i beta' "$tmpdir/in.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-python3-hashlib-md5)
    python3 >"$tmpdir/out" <<'PYCASE'
import hashlib
print(hashlib.md5(b'abc').hexdigest())
PYCASE
    validator_assert_contains "$tmpdir/out" '900150983cd24fb0d6963f7d28e17f72'
    ;;
  usage-findutils-mindepth)
    mkdir -p "$tmpdir/tree/sub"
    : >"$tmpdir/tree/root.txt"
    : >"$tmpdir/tree/sub/leaf.txt"
    find "$tmpdir/tree" -mindepth 2 -type f | sort >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'leaf.txt'
    if grep -Fq 'root.txt' "$tmpdir/out"; then
      printf 'mindepth output unexpectedly included root.txt\n' >&2
      exit 1
    fi
    ;;
  usage-tar-strip-components)
    mkdir -p "$tmpdir/in/top/inner" "$tmpdir/out"
    printf 'strip payload\n' >"$tmpdir/in/top/inner/file.txt"
    tar -cf "$tmpdir/archive.tar" -C "$tmpdir/in" top
    tar -xf "$tmpdir/archive.tar" --strip-components=2 -C "$tmpdir/out"
    validator_assert_contains "$tmpdir/out/file.txt" 'strip payload'
    ;;
  *)
    printf 'unknown libc6 further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
