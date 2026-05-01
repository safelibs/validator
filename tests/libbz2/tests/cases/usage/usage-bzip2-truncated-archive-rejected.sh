#!/usr/bin/env bash
# @testcase: usage-bzip2-truncated-archive-rejected
# @title: bzip2 -t rejects truncated archive
# @description: Truncates the trailing bytes of a valid .bz2 stream and verifies bzip2 -t fails with a non-zero exit and an unexpected-end-of-file or integrity diagnostic on stderr.
# @timeout: 120
# @tags: usage, bzip2, negative
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-truncated-archive-rejected"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
for i in range(1024):
    sys.stdout.write("truncation probe %05d\n" % i)
' >"$tmpdir/in.txt"

bzip2 -c "$tmpdir/in.txt" >"$tmpdir/full.bz2"
bzip2 -t "$tmpdir/full.bz2"

full_size=$(wc -c <"$tmpdir/full.bz2")
keep=$(( full_size - 16 ))
[[ $keep -gt 4 ]]
dd if="$tmpdir/full.bz2" of="$tmpdir/short.bz2" bs=1 count="$keep" status=none

short_size=$(wc -c <"$tmpdir/short.bz2")
[[ $short_size -lt $full_size ]]

set +e
bzip2 -t "$tmpdir/short.bz2" >"$tmpdir/out" 2>"$tmpdir/err"
status=$?
set -e

[[ $status -ne 0 ]] || { printf 'bzip2 -t accepted truncated stream\n' >&2; exit 1; }
test -s "$tmpdir/err"
grep -qiE 'unexpected end|integrity|corrupt|file ends unexpectedly' "$tmpdir/err" || {
  printf 'unexpected stderr for truncated stream:\n' >&2
  cat "$tmpdir/err" >&2
  exit 1
}
