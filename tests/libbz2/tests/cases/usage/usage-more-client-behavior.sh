#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-bzip2-stdin-stdout-roundtrip)
    printf 'stdin roundtrip payload\n' | bzip2 -c >"$tmpdir/in.bz2"
    bzip2 -dc "$tmpdir/in.bz2" >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'stdin roundtrip payload'
    ;;
  usage-bunzip2-stdout-sample1)
    validator_require_file "$VALIDATOR_SAMPLE_ROOT/sample1.bz2"
    validator_require_file "$VALIDATOR_SAMPLE_ROOT/sample1.ref"
    bunzip2 -c "$VALIDATOR_SAMPLE_ROOT/sample1.bz2" >"$tmpdir/out.txt"
    cmp "$VALIDATOR_SAMPLE_ROOT/sample1.ref" "$tmpdir/out.txt"
    ;;
  usage-bzcat-sample2-lines)
    validator_require_file "$VALIDATOR_SAMPLE_ROOT/sample2.bz2"
    bzcat "$VALIDATOR_SAMPLE_ROOT/sample2.bz2" >"$tmpdir/out.txt"
    test "$(wc -l <"$tmpdir/out.txt")" -gt 0
    ;;
  usage-bzgrep-fixed-string)
    printf 'alpha\nneedle\nbeta\n' >"$tmpdir/in.txt"
    bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
    bzgrep -F 'needle' "$tmpdir/in.txt.bz2" >"$tmpdir/out"
    grep -Fxq 'needle' "$tmpdir/out"
    ;;
  usage-bzgrep-count)
    printf 'match\nskip\nmatch\n' >"$tmpdir/in.txt"
    bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
    bzgrep -c 'match' "$tmpdir/in.txt.bz2" >"$tmpdir/out"
    grep -Fxq '2' "$tmpdir/out"
    ;;
  usage-bzdiff-different-exit)
    printf 'alpha\n' >"$tmpdir/one.txt"
    printf 'beta\n' >"$tmpdir/two.txt"
    bzip2 -c "$tmpdir/one.txt" >"$tmpdir/one.txt.bz2"
    bzip2 -c "$tmpdir/two.txt" >"$tmpdir/two.txt.bz2"
    if bzdiff "$tmpdir/one.txt.bz2" "$tmpdir/two.txt.bz2" >"$tmpdir/out" 2>&1; then
      printf 'bzdiff unexpectedly reported identical files\n' >&2
      exit 1
    fi
    validator_assert_contains "$tmpdir/out" '< alpha'
    validator_assert_contains "$tmpdir/out" '> beta'
    ;;
  usage-bzcmp-different-exit)
    printf 'left\n' >"$tmpdir/one.txt"
    printf 'right\n' >"$tmpdir/two.txt"
    bzip2 -c "$tmpdir/one.txt" >"$tmpdir/one.txt.bz2"
    bzip2 -c "$tmpdir/two.txt" >"$tmpdir/two.txt.bz2"
    if bzcmp "$tmpdir/one.txt.bz2" "$tmpdir/two.txt.bz2" >"$tmpdir/out" 2>&1; then
      printf 'bzcmp unexpectedly reported identical files\n' >&2
      exit 1
    fi
    validator_assert_contains "$tmpdir/out" 'differ:'
    ;;
  usage-bzip2-best-compress-file)
    printf 'best compression payload\n%.0s' $(seq 1 32) >"$tmpdir/in.txt"
    cp "$tmpdir/in.txt" "$tmpdir/best.txt"
    bzip2 -9 "$tmpdir/best.txt"
    bzip2 -dc "$tmpdir/best.txt.bz2" >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'best compression payload'
    ;;
  usage-bzip2-fast-compress-file)
    printf 'fast compression payload\n%.0s' $(seq 1 32) >"$tmpdir/in.txt"
    cp "$tmpdir/in.txt" "$tmpdir/fast.txt"
    bzip2 -1 "$tmpdir/fast.txt"
    bzip2 -dc "$tmpdir/fast.txt.bz2" >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'fast compression payload'
    ;;
  usage-bzip2-empty-stdout)
    : >"$tmpdir/empty.txt"
    bzip2 -c "$tmpdir/empty.txt" >"$tmpdir/empty.txt.bz2"
    bzip2 -dc "$tmpdir/empty.txt.bz2" >"$tmpdir/out.txt"
    test "$(wc -c <"$tmpdir/out.txt")" -eq 0
    ;;
  *)
    printf 'unknown libbz2 additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
