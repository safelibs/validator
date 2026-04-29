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
  usage-bzip2-batch11-bzgrep-after-context)
    printf 'alpha\nbeta\ngamma\n' >"$tmpdir/plain.txt"
    bzip2 -k "$tmpdir/plain.txt"
    bzgrep -A 1 'alpha' "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'beta'
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
  usage-bzip2-batch11-bzgrep-quiet-match)
    printf 'quiet needle\n' >"$tmpdir/plain.txt"
    bzip2 -k "$tmpdir/plain.txt"
    bzgrep -q 'needle' "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
    test ! -s "$tmpdir/out"
    ;;
  usage-bzip2-batch11-bzmore-pager-cat)
    printf 'more payload\n' >"$tmpdir/plain.txt"
    bzip2 -k "$tmpdir/plain.txt"
    PAGER=cat bzmore "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'more payload'
    ;;
  usage-bzip2-batch11-bzgrep-before-context)
    printf 'alpha\nbeta\ngamma\n' >"$tmpdir/plain.txt"
    bzip2 -k "$tmpdir/plain.txt"
    bzgrep -B 1 'gamma' "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-bzip2-batch11-bzgrep-nonmatching-file)
    printf 'needle\n' >"$tmpdir/a.txt"
    printf 'other\n' >"$tmpdir/b.txt"
    bzip2 -k "$tmpdir/a.txt" "$tmpdir/b.txt"
    bzgrep -L 'needle' "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'b.txt.bz2'
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
