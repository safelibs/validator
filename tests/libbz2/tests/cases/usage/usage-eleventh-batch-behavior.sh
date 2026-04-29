#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-bzip2-batch11-decompress-c-flag)
    printf 'decompress c flag\n' >"$tmpdir/plain.txt"
    bzip2 -k "$tmpdir/plain.txt"
    bzip2 -dc "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'decompress c flag'
    ;;
  usage-bzip2-batch11-compress-c-flag)
    printf 'compress c flag\n' >"$tmpdir/plain.txt"
    bzip2 -c "$tmpdir/plain.txt" >"$tmpdir/plain.bz2"
    bunzip2 -c "$tmpdir/plain.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'compress c flag'
    ;;
  usage-bzip2-batch11-bzgrep-extended-regexp)
    printf 'alpha\nbeta\ngamma\n' >"$tmpdir/plain.txt"
    bzip2 -k "$tmpdir/plain.txt"
    bzgrep -E 'alpha|gamma' "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha'
    validator_assert_contains "$tmpdir/out" 'gamma'
    ;;
  usage-bzip2-batch11-bzgrep-no-filename)
    printf 'needle one\nneedle two\n' >"$tmpdir/plain.txt"
    bzip2 -k "$tmpdir/plain.txt"
    bzgrep -h 'needle' "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
    test "$(grep -c '^needle' "$tmpdir/out")" -eq 2
    ;;
  usage-bzip2-batch11-bzcat-numbered-pipe)
    printf 'first\nsecond\n' >"$tmpdir/plain.txt"
    bzip2 -k "$tmpdir/plain.txt"
    bzcat "$tmpdir/plain.txt.bz2" | nl -ba >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '1'
    validator_assert_contains "$tmpdir/out" 'second'
    ;;
  usage-bzip2-batch11-test-quiet)
    printf 'quiet test\n' >"$tmpdir/plain.txt"
    bzip2 -k "$tmpdir/plain.txt"
    bzip2 -tq "$tmpdir/plain.txt.bz2"
    ;;
  usage-bzip2-batch11-fast-stdout-roundtrip)
    printf 'fast stdout\n' >"$tmpdir/plain.txt"
    bzip2 -1 -c "$tmpdir/plain.txt" | bunzip2 -c >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'fast stdout'
    ;;
  usage-bzip2-batch11-best-stdout-roundtrip)
    printf 'best stdout\n' >"$tmpdir/plain.txt"
    bzip2 -9 -c "$tmpdir/plain.txt" | bunzip2 -c >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'best stdout'
    ;;
  usage-bzip2-batch11-decompress-replace)
    printf 'replace input\n' >"$tmpdir/plain.txt"
    bzip2 "$tmpdir/plain.txt"
    bunzip2 "$tmpdir/plain.txt.bz2"
    validator_assert_contains "$tmpdir/plain.txt" 'replace input'
    ;;
  usage-bzip2-batch11-bzgrep-fixed-brackets)
    printf '[literal]\nregex\n' >"$tmpdir/plain.txt"
    bzip2 -k "$tmpdir/plain.txt"
    bzgrep -F '[literal]' "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '[literal]'
    ;;
  *)
    printf 'unknown libbz2 eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
