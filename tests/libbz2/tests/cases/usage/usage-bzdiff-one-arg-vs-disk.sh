#!/usr/bin/env bash
# @testcase: usage-bzdiff-one-arg-vs-disk
# @title: bzdiff one-arg compares file.bz2 against on-disk file
# @description: Exercises bzdiff's documented single-argument mode where bzdiff file.bz2 decompresses file.bz2 and diffs it against the sibling uncompressed file on disk, covering both the matching and modified-on-disk cases.
# @timeout: 180
# @tags: usage, bzip2, diff, single-arg
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'one-arg bzdiff payload\n' >"$tmpdir/sample.txt"
# Keep the uncompressed sibling on disk; the single-arg form needs both.
bzip2 -k "$tmpdir/sample.txt"
validator_require_file "$tmpdir/sample.txt"
validator_require_file "$tmpdir/sample.txt.bz2"

# Matching case: bzdiff sample.txt.bz2 should exit 0 with empty stdout.
bzdiff "$tmpdir/sample.txt.bz2" >"$tmpdir/match.out" 2>"$tmpdir/match.err"
[[ ! -s "$tmpdir/match.out" ]] || {
  printf 'expected empty diff output, got:\n' >&2
  cat "$tmpdir/match.out" >&2
  exit 1
}

# Modify the uncompressed sibling so the .bz2 contents disagree with disk.
printf 'extra line appended after compress\n' >>"$tmpdir/sample.txt"

# Diverging case: bzdiff must exit 1 and report the appended line.
set +e
bzdiff "$tmpdir/sample.txt.bz2" >"$tmpdir/ne.out" 2>"$tmpdir/ne.err"
rc=$?
set -e
[[ "$rc" -eq 1 ]] || {
  printf 'expected bzdiff one-arg exit 1 on diverging sibling, got %s\n' "$rc" >&2
  cat "$tmpdir/ne.out" "$tmpdir/ne.err" >&2 || true
  exit 1
}
validator_assert_contains "$tmpdir/ne.out" 'extra line appended after compress'
