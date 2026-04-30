#!/usr/bin/env bash
# @testcase: usage-bzgrep-null-terminated-filenames
# @title: bzgrep -l accepts --null and lists matching filenames
# @description: Runs bzgrep -l --null over two compressed files where only one matches and verifies the wrapper accepts the --null flag, lists exactly the matching filename, and skips the non-matching file. (Ubuntu's bzgrep prints filenames itself in -l mode, so the NUL request from --null is absorbed by the wrapper rather than reaching grep.)
# @timeout: 180
# @tags: usage, bzgrep, null
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-null-terminated-filenames"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nneedle here\ngamma\n' >"$tmpdir/match.txt"
printf 'beta\ndelta\nepsilon\n' >"$tmpdir/nomatch.txt"

bzip2 -zk "$tmpdir/match.txt"
bzip2 -zk "$tmpdir/nomatch.txt"

# bzgrep must accept --null without an option-not-supported failure.
# bzgrep -l returns the worst per-file grep exit code; the non-matching file
# produces exit 1, which the wrapper propagates. Tolerate exit 1 and only
# treat >=2 as a hard failure.
set +e
( cd "$tmpdir" && bzgrep -l --null needle match.txt.bz2 nomatch.txt.bz2 ) >"$tmpdir/out"
rc=$?
set -e
if (( rc >= 2 )); then
  printf 'bzgrep -l --null failed with exit %s\n' "$rc" >&2
  exit 1
fi

# Exactly one line of output: the matching filename.
line_count=$(wc -l <"$tmpdir/out")
[[ "$line_count" -eq 1 ]] || {
  printf 'expected 1 filename, got %s\n' "$line_count" >&2
  od -c "$tmpdir/out" | sed -n '1,5p' >&2
  exit 1
}

validator_assert_contains "$tmpdir/out" 'match.txt.bz2'
if grep -Fq 'nomatch.txt.bz2' "$tmpdir/out"; then
  printf 'unexpected nomatch.txt.bz2 in -l output\n' >&2
  sed -n '1,5p' "$tmpdir/out" >&2
  exit 1
fi
