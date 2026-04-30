#!/usr/bin/env bash
# @testcase: usage-bzip2-test-empty-file
# @title: bzip2 -t rejects empty file
# @description: Runs bzip2 -t on a zero-byte file and verifies it fails with a non-zero exit status and a diagnostic on stderr.
# @timeout: 120
# @tags: usage, bzip2, negative
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-test-empty-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/empty.bz2"
test ! -s "$tmpdir/empty.bz2"

if bzip2 -t "$tmpdir/empty.bz2" >"$tmpdir/out" 2>"$tmpdir/err"; then
  printf 'bzip2 -t unexpectedly accepted an empty file\n' >&2
  exit 1
fi
test ! -s "$tmpdir/out"
test -s "$tmpdir/err"
# bzip2 reports either "file ends unexpectedly" or "Compressed file ends unexpectedly".
grep -qiE 'ends unexpectedly|not a bzip2 file' "$tmpdir/err" || {
  printf 'unexpected stderr for empty .bz2:\n' >&2
  cat "$tmpdir/err" >&2
  exit 1
}
