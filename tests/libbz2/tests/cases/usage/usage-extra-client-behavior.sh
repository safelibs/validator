#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-bzip2-sample1-fixture|usage-bzip2-sample2-fixture|usage-bzip2-sample3-fixture)
    sample=${case_id#usage-bzip2-}
    sample=${sample%-fixture}
    validator_require_file "$VALIDATOR_SAMPLE_ROOT/${sample}.bz2"
    validator_require_file "$VALIDATOR_SAMPLE_ROOT/${sample}.ref"
    bzip2 -dc "$VALIDATOR_SAMPLE_ROOT/${sample}.bz2" >"$tmpdir/out"
    cmp "$VALIDATOR_SAMPLE_ROOT/${sample}.ref" "$tmpdir/out"
    ;;
  usage-bzip2-best-stdout)
    for i in $(seq 1 40); do printf 'best compression payload %02d\n' "$i"; done >"$tmpdir/in.txt"
    bzip2 -9 -c "$tmpdir/in.txt" | bzip2 -dc >"$tmpdir/out"
    cmp "$tmpdir/in.txt" "$tmpdir/out"
    ;;
  usage-bzip2-fast-stdout)
    for i in $(seq 1 40); do printf 'fast compression payload %02d\n' "$i"; done >"$tmpdir/in.txt"
    bzip2 -1 -c "$tmpdir/in.txt" | bzip2 -dc >"$tmpdir/out"
    cmp "$tmpdir/in.txt" "$tmpdir/out"
    ;;
  usage-bzip2-verbose-test)
    printf 'verbose integrity payload\n' >"$tmpdir/in.txt"
    bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
    bzip2 -tvv "$tmpdir/in.txt.bz2" >"$tmpdir/out" 2>&1
    validator_assert_contains "$tmpdir/out" 'ok'
    ;;
  usage-bzcat-alias)
    printf 'bzcat payload\n' >"$tmpdir/in.txt"
    bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
    bzcat "$tmpdir/in.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'bzcat payload'
    ;;
  usage-bzgrep-search)
    printf 'alpha\nbeta\ngamma\n' >"$tmpdir/in.txt"
    bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
    bzgrep '^beta$' "$tmpdir/in.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-bzdiff-identical)
    printf 'same payload\n' >"$tmpdir/a.txt"
    cp "$tmpdir/a.txt" "$tmpdir/b.txt"
    bzip2 -c "$tmpdir/a.txt" >"$tmpdir/a.txt.bz2"
    bzip2 -c "$tmpdir/b.txt" >"$tmpdir/b.txt.bz2"
    bzdiff "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/out"
    test ! -s "$tmpdir/out"
    ;;
  usage-bzip2-corrupt-rejection)
    printf 'corrupt rejection payload\n' >"$tmpdir/in.txt"
    bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
    head -c 10 "$tmpdir/in.txt.bz2" >"$tmpdir/truncated.bz2"
    if bzip2 -t "$tmpdir/truncated.bz2" >"$tmpdir/out" 2>"$tmpdir/err"; then
      printf 'truncated bzip2 stream unexpectedly passed\n' >&2
      exit 1
    fi
    test -s "$tmpdir/err"
    ;;
  usage-bunzip2-alias)
    printf 'bunzip2 payload\n' >"$tmpdir/in.txt"
    bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
    bunzip2 -c "$tmpdir/in.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'bunzip2 payload'
    ;;
  usage-bzcmp-identical)
    printf 'same payload\n' >"$tmpdir/a.txt"
    cp "$tmpdir/a.txt" "$tmpdir/b.txt"
    bzip2 -c "$tmpdir/a.txt" >"$tmpdir/a.txt.bz2"
    bzip2 -c "$tmpdir/b.txt" >"$tmpdir/b.txt.bz2"
    bzcmp "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/out"
    test ! -s "$tmpdir/out"
    ;;
  usage-bzgrep-line-number)
    printf 'alpha\nbeta\ngamma\n' >"$tmpdir/in.txt"
    bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
    bzgrep -n '^beta$' "$tmpdir/in.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2:beta'
    ;;
  usage-bzip2-empty-file)
    : >"$tmpdir/empty.txt"
    bzip2 -c "$tmpdir/empty.txt" | bzip2 -dc >"$tmpdir/out"
    test ! -s "$tmpdir/out"
    ;;
  usage-bzip2-medium-stdout)
    for i in $(seq 1 20); do printf 'medium compression payload %02d\n' "$i"; done >"$tmpdir/in.txt"
    bzip2 -7 -c "$tmpdir/in.txt" | bzip2 -dc >"$tmpdir/out"
    cmp "$tmpdir/in.txt" "$tmpdir/out"
    ;;
  usage-bzip2-test-sample1|usage-bzip2-test-sample2|usage-bzip2-test-sample3)
    sample=${case_id#usage-bzip2-test-}
    validator_require_file "$VALIDATOR_SAMPLE_ROOT/${sample}.bz2"
    bzip2 -t "$VALIDATOR_SAMPLE_ROOT/${sample}.bz2"
    printf '%s ok\n' "$sample"
    ;;
  usage-bzip2-recompress-file)
    printf 'recompress payload\n' >"$tmpdir/in.txt"
    bzip2 -c "$tmpdir/in.txt" >"$tmpdir/one.bz2"
    bunzip2 -c "$tmpdir/one.bz2" >"$tmpdir/plain.txt"
    bzip2 -c "$tmpdir/plain.txt" >"$tmpdir/two.bz2"
    cmp "$tmpdir/plain.txt" <(bzip2 -dc "$tmpdir/two.bz2")
    ;;
  usage-bzip2-decompress-suffix)
    printf 'suffix payload\n' >"$tmpdir/name.txt"
    bzip2 -c "$tmpdir/name.txt" >"$tmpdir/name.txt.bz2"
    rm "$tmpdir/name.txt"
    bunzip2 "$tmpdir/name.txt.bz2"
    validator_assert_contains "$tmpdir/name.txt" 'suffix payload'
    ;;
  *)
    printf 'unknown libbz2 extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
