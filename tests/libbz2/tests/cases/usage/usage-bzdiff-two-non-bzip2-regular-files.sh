#!/usr/bin/env bash
# @testcase: usage-bzdiff-two-non-bzip2-regular-files
# @title: bzdiff diffs two plain (non-bzip2) regular files via diff fallback
# @description: Invokes bzdiff with two regular text files (no .bz2 extension or magic) and verifies bzdiff still reports the textual difference - bzdiff falls back to diff when its arguments are not bzip2 streams. Confirms the "<" and ">" diff markers, and that two identical plain files report no difference.
# @timeout: 180
# @tags: usage, bzdiff, plain-files
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\ngamma\n' >"$tmpdir/left.txt"
printf 'alpha\ndelta\ngamma\n' >"$tmpdir/right.txt"

# Sanity: these must not be bzip2 streams.
for f in "$tmpdir/left.txt" "$tmpdir/right.txt"; do
  magic=$(head -c 3 "$f")
  if [[ "$magic" == "BZh" ]]; then
    printf 'fixture %s unexpectedly looks like a bzip2 stream\n' "$f" >&2
    exit 1
  fi
done

# Different content -> bzdiff exits non-zero with diff-style markers.
set +e
bzdiff "$tmpdir/left.txt" "$tmpdir/right.txt" >"$tmpdir/diff.out" 2>"$tmpdir/diff.err"
rc=$?
set -e
[[ "$rc" -eq 1 ]] || {
  printf 'expected bzdiff exit 1 on differing plain files, got %s\n' "$rc" >&2
  sed -n '1,40p' "$tmpdir/diff.out" >&2
  sed -n '1,40p' "$tmpdir/diff.err" >&2
  exit 1
}

validator_assert_contains "$tmpdir/diff.out" '< beta'
validator_assert_contains "$tmpdir/diff.out" '> delta'

# Identical plain files -> bzdiff exits 0 with empty stdout.
cp "$tmpdir/left.txt" "$tmpdir/copy.txt"
bzdiff "$tmpdir/left.txt" "$tmpdir/copy.txt" >"$tmpdir/same.out" 2>"$tmpdir/same.err"
[[ ! -s "$tmpdir/same.out" ]] || {
  printf 'bzdiff produced unexpected output for identical plain files:\n' >&2
  sed -n '1,40p' "$tmpdir/same.out" >&2
  exit 1
}
