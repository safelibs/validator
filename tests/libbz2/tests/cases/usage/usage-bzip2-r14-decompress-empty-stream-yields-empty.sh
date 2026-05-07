#!/usr/bin/env bash
# @testcase: usage-bzip2-r14-decompress-empty-stream-yields-empty
# @title: bzip2 -d round-trips a zero-byte input back to zero bytes
# @description: Compresses a zero-byte input file with "bzip2 -c" producing a small but non-empty .bz2 stream (containing the empty-block end marker), then decompresses with "bzip2 -dc" and asserts the recovered output is exactly zero bytes — pinning empty-input round-trip behavior.
# @timeout: 30
# @tags: usage, bzip2, empty
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/empty.txt"
[[ ! -s "$tmpdir/empty.txt" ]]

bzip2 -c "$tmpdir/empty.txt" >"$tmpdir/empty.bz2"
[[ -s "$tmpdir/empty.bz2" ]]

magic=$(head -c 3 "$tmpdir/empty.bz2")
test "$magic" = "BZh"

bzip2 -dc "$tmpdir/empty.bz2" >"$tmpdir/decoded.bin"
[[ ! -s "$tmpdir/decoded.bin" ]]
