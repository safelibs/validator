#!/usr/bin/env bash
# @testcase: usage-bzip2-batch12-decompress-multistream-three-streams
# @title: bzip2 -d concatenated three streams produces concatenated payload
# @description: Compresses three different payloads, concatenates the three .bz2 streams into a single file, and verifies bzip2 -d returns the concatenated original payloads.
# @timeout: 60
# @tags: usage, compression, multistream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'stream1-payload\n' >"$tmpdir/p1.txt"
printf 'stream2-different\n' >"$tmpdir/p2.txt"
printf 'stream3-final\n' >"$tmpdir/p3.txt"

bzip2 -c "$tmpdir/p1.txt" >"$tmpdir/concat.bz2"
bzip2 -c "$tmpdir/p2.txt" >>"$tmpdir/concat.bz2"
bzip2 -c "$tmpdir/p3.txt" >>"$tmpdir/concat.bz2"

cat "$tmpdir/p1.txt" "$tmpdir/p2.txt" "$tmpdir/p3.txt" >"$tmpdir/expected.txt"

bzip2 -dc "$tmpdir/concat.bz2" >"$tmpdir/decoded.txt"
cmp "$tmpdir/expected.txt" "$tmpdir/decoded.txt"
