#!/usr/bin/env bash
# @testcase: usage-bzip2-corrupt-rejection
# @title: bzip2 rejects corrupt stream
# @description: Requires bzip2 integrity checking to reject a truncated compressed stream.
# @timeout: 180
# @tags: usage, compression, negative
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-corrupt-rejection"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'corrupt rejection payload\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
head -c 10 "$tmpdir/in.txt.bz2" >"$tmpdir/truncated.bz2"
if bzip2 -t "$tmpdir/truncated.bz2" >"$tmpdir/out" 2>"$tmpdir/err"; then
  printf 'truncated bzip2 stream unexpectedly passed\n' >&2
  exit 1
fi
test -s "$tmpdir/err"
