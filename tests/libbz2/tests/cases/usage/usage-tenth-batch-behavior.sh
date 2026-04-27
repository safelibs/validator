#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-bzip2-block-six-roundtrip)
    for i in $(seq 1 64); do printf 'block six payload %02d\n' "$i"; done >"$tmpdir/in.txt"
    bzip2 -6 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
    bzip2 -dc "$tmpdir/in.txt.bz2" >"$tmpdir/out.txt"
    cmp "$tmpdir/in.txt" "$tmpdir/out.txt"
    ;;
  usage-bzip2-decompress-quiet-stdin)
    printf 'quiet decompress payload\n' >"$tmpdir/in.txt"
    bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"
    bzip2 -dcq <"$tmpdir/in.bz2" >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'quiet decompress payload'
    ;;
  usage-bzip2-force-decompress-suffix)
    printf 'force suffix payload\n' >"$tmpdir/in.txt"
    bzip2 "$tmpdir/in.txt"
    cp "$tmpdir/in.txt.bz2" "$tmpdir/in.txt"
    bzip2 -df "$tmpdir/in.txt.bz2"
    validator_assert_contains "$tmpdir/in.txt" 'force suffix payload'
    ;;
  usage-bzip2-test-multi-files)
    printf 'first stream\n' >"$tmpdir/one.txt"
    printf 'second stream\n' >"$tmpdir/two.txt"
    bzip2 -k "$tmpdir/one.txt" "$tmpdir/two.txt"
    bzip2 -t "$tmpdir/one.txt.bz2" "$tmpdir/two.txt.bz2"
    ;;
  usage-bzcat-stdin-input)
    printf 'bzcat stdin payload\n' >"$tmpdir/in.txt"
    bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"
    bzcat <"$tmpdir/in.bz2" >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'bzcat stdin payload'
    ;;
  usage-bzgrep-invert-match)
    printf 'alpha\nbeta\ngamma\n' >"$tmpdir/in.txt"
    bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
    bzgrep -v 'beta' "$tmpdir/in.txt.bz2" >"$tmpdir/out"
    grep -Fxq 'alpha' "$tmpdir/out"
    grep -Fxq 'gamma' "$tmpdir/out"
    if grep -Fxq 'beta' "$tmpdir/out"; then exit 1; fi
    ;;
  usage-bzgrep-extended-regexp)
    printf 'apple\nbanana\ncherry\n' >"$tmpdir/in.txt"
    bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
    bzgrep -E 'app|cher' "$tmpdir/in.txt.bz2" >"$tmpdir/out"
    grep -Fxq 'apple' "$tmpdir/out"
    grep -Fxq 'cherry' "$tmpdir/out"
    ;;
  usage-bzip2-stdin-pipe-roundtrip)
    printf 'pipeline payload one\n' >"$tmpdir/a.txt"
    bzip2 -c "$tmpdir/a.txt" | bzip2 -dc >"$tmpdir/out.txt"
    cmp "$tmpdir/a.txt" "$tmpdir/out.txt"
    ;;
  usage-bzip2-decompress-replace-input)
    printf 'replace input payload\n' >"$tmpdir/in.txt"
    bzip2 "$tmpdir/in.txt"
    test ! -e "$tmpdir/in.txt"
    bzip2 -d "$tmpdir/in.txt.bz2"
    validator_require_file "$tmpdir/in.txt"
    test ! -e "$tmpdir/in.txt.bz2"
    validator_assert_contains "$tmpdir/in.txt" 'replace input payload'
    ;;
  usage-bzip2-three-stream-concat)
    printf 'one\n' >"$tmpdir/one.txt"
    printf 'two\n' >"$tmpdir/two.txt"
    printf 'three\n' >"$tmpdir/three.txt"
    bzip2 -c "$tmpdir/one.txt" >"$tmpdir/concat.bz2"
    bzip2 -c "$tmpdir/two.txt" >>"$tmpdir/concat.bz2"
    bzip2 -c "$tmpdir/three.txt" >>"$tmpdir/concat.bz2"
    bzip2 -dc "$tmpdir/concat.bz2" >"$tmpdir/out.txt"
    grep -Fxq 'one' "$tmpdir/out.txt"
    grep -Fxq 'two' "$tmpdir/out.txt"
    grep -Fxq 'three' "$tmpdir/out.txt"
    ;;
  *)
    printf 'unknown libbz2 tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
