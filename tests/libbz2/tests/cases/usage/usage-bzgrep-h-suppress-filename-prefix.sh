#!/usr/bin/env bash
# @testcase: usage-bzgrep-h-suppress-filename-prefix
# @title: bzgrep -h suppresses the per-line filename prefix across multiple inputs
# @description: Searches two compressed files at once with bzgrep -h and verifies that, unlike the default multi-file mode, no "filename:" prefix is attached to each match line. The raw matched lines must appear exactly as in the source.
# @timeout: 180
# @tags: usage, bzgrep, no-filename
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'needle one\nfiller\nneedle two\n' >"$tmpdir/a.txt"
printf 'unrelated\nneedle three\n' >"$tmpdir/b.txt"

bzip2 -zk "$tmpdir/a.txt"
bzip2 -zk "$tmpdir/b.txt"

# Confirm the default (no -h) prepends filenames so we know -h is doing real work.
( cd "$tmpdir" && bzgrep needle a.txt.bz2 b.txt.bz2 ) >"$tmpdir/default.out"
grep -q '^a\.txt\.bz2:needle one$' "$tmpdir/default.out" || {
  printf 'baseline: expected filename prefix in default bzgrep output\n' >&2
  sed -n '1,20p' "$tmpdir/default.out" >&2
  exit 1
}

# Now -h: filename prefixes must be gone.
( cd "$tmpdir" && bzgrep -h needle a.txt.bz2 b.txt.bz2 ) >"$tmpdir/out"

if grep -Eq '^(a|b)\.txt\.bz2:' "$tmpdir/out"; then
  printf 'bzgrep -h leaked filename prefix:\n' >&2
  sed -n '1,20p' "$tmpdir/out" >&2
  exit 1
fi

# Exactly the three matched raw lines.
line_count=$(wc -l <"$tmpdir/out")
[[ "$line_count" -eq 3 ]] || {
  printf 'expected 3 output lines, got %s\n' "$line_count" >&2
  sed -n '1,20p' "$tmpdir/out" >&2
  exit 1
}

grep -Fxq 'needle one' "$tmpdir/out"
grep -Fxq 'needle two' "$tmpdir/out"
grep -Fxq 'needle three' "$tmpdir/out"
