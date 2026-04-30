#!/usr/bin/env bash
# @testcase: usage-bunzip2-multistream-concatenation
# @title: bunzip2 expands concatenated multi-stream input
# @description: Concatenates three independently compressed bzip2 streams and verifies bunzip2 reassembles the exact joined payload via stdin.
# @timeout: 180
# @tags: usage, decompression, multistream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first-stream-payload\n' >"$tmpdir/a.txt"
printf 'second-stream-payload\n' >"$tmpdir/b.txt"
printf 'third-stream-payload\n'  >"$tmpdir/c.txt"

# Independently compress each fragment.
bzip2 -c "$tmpdir/a.txt" >"$tmpdir/a.bz2"
bzip2 -c "$tmpdir/b.txt" >"$tmpdir/c2.bz2" # intentional name; rename below.
mv "$tmpdir/c2.bz2" "$tmpdir/b.bz2"
bzip2 -c "$tmpdir/c.txt" >"$tmpdir/c.bz2"

# Expected uncompressed concatenation.
cat "$tmpdir/a.txt" "$tmpdir/b.txt" "$tmpdir/c.txt" >"$tmpdir/expected"
expected_sha=$(sha256sum "$tmpdir/expected" | awk '{print $1}')

# Pipe the concatenated streams through bunzip2 on stdin.
cat "$tmpdir/a.bz2" "$tmpdir/b.bz2" "$tmpdir/c.bz2" | bunzip2 >"$tmpdir/out"
cmp "$tmpdir/expected" "$tmpdir/out"

actual_sha=$(sha256sum "$tmpdir/out" | awk '{print $1}')
[[ "$expected_sha" == "$actual_sha" ]]

# Also verify bzip2 -t accepts the concatenated stream as a multi-member file.
cat "$tmpdir/a.bz2" "$tmpdir/b.bz2" "$tmpdir/c.bz2" >"$tmpdir/all.bz2"
bzip2 -t "$tmpdir/all.bz2"
