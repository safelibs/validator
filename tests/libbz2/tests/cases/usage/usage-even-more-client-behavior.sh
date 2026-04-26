#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample_root="$VALIDATOR_SAMPLE_ROOT"

case "$case_id" in
  usage-bzip2-keep-input-compress)
    printf 'keep input payload\n' >"$tmpdir/data.txt"
    bzip2 -k "$tmpdir/data.txt"
    validator_assert_contains "$tmpdir/data.txt" 'keep input payload'
    bzip2 -dc "$tmpdir/data.txt.bz2" >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'keep input payload'
    ;;
  usage-bzip2-stdin-file-output)
    printf 'stdin file output payload\n' | bzip2 -c >"$tmpdir/stdin.bz2"
    bzip2 -dc "$tmpdir/stdin.bz2" >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'stdin file output payload'
    ;;
  usage-bunzip2-stdin-output)
    cat "$sample_root/sample2.bz2" | bunzip2 -c >"$tmpdir/out.txt"
    cmp "$sample_root/sample2.ref" "$tmpdir/out.txt"
    ;;
  usage-bzgrep-ignore-case)
    printf 'Alpha\nneedle\nBETA\n' >"$tmpdir/input.txt"
    bzip2 -c "$tmpdir/input.txt" >"$tmpdir/input.txt.bz2"
    bzgrep -i 'beta' "$tmpdir/input.txt.bz2" >"$tmpdir/out"
    grep -Fxq 'BETA' "$tmpdir/out"
    ;;
  usage-bzgrep-filename-space)
    printf 'space needle\n' >"$tmpdir/space name.txt"
    bzip2 -c "$tmpdir/space name.txt" >"$tmpdir/space name.txt.bz2"
    bzgrep -H 'needle' "$tmpdir/space name.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'space name.txt.bz2'
    validator_assert_contains "$tmpdir/out" 'needle'
    ;;
  usage-bzip2-verbose-test-file)
    bzip2 -tv "$sample_root/sample1.bz2" >"$tmpdir/out" 2>&1
    validator_assert_contains "$tmpdir/out" 'ok'
    ;;
  usage-bzcat-sample3-compare)
    bzcat "$sample_root/sample3.bz2" >"$tmpdir/out.txt"
    cmp "$sample_root/sample3.ref" "$tmpdir/out.txt"
    ;;
  usage-bzip2-sample3-stdout)
    bzip2 -dc "$sample_root/sample3.bz2" >"$tmpdir/out.txt"
    cmp "$sample_root/sample3.ref" "$tmpdir/out.txt"
    ;;
  usage-bzip2-custom-suffix-roundtrip)
    printf 'custom suffix payload\n' >"$tmpdir/custom.txt"
    bzip2 -zk "$tmpdir/custom.txt"
    mv "$tmpdir/custom.txt.bz2" "$tmpdir/custom.txt.tbz"
    bzip2 -dc "$tmpdir/custom.txt.tbz" >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'custom suffix payload'
    ;;
  usage-bzdiff-space-filenames)
    printf 'alpha\n' >"$tmpdir/left.txt"
    printf 'beta\n' >"$tmpdir/right.txt"
    bzip2 -c "$tmpdir/left.txt" >"$tmpdir/left.txt.bz2"
    bzip2 -c "$tmpdir/right.txt" >"$tmpdir/right.txt.bz2"
    if bzdiff "$tmpdir/left.txt.bz2" "$tmpdir/right.txt.bz2" >"$tmpdir/out" 2>&1; then
      printf 'bzdiff unexpectedly reported identical content\n' >&2
      exit 1
    fi
    validator_assert_contains "$tmpdir/out" '< alpha'
    validator_assert_contains "$tmpdir/out" '> beta'
    ;;
  *)
    printf 'unknown libbz2 even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
