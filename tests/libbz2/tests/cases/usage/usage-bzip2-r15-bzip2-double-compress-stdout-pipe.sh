#!/usr/bin/env bash
# @testcase: usage-bzip2-r15-bzip2-double-compress-stdout-pipe
# @title: bzip2 double-encode then double-decode pipeline preserves the source bytes
# @description: Pipes a payload through "bzip2 -c | bzip2 -c" producing a doubly-compressed .bz2.bz2 stream, then reverses the pipe through "bunzip2 -c | bunzip2 -c" and asserts the recovered output matches the source sha256. Also asserts the doubly-compressed blob's first three bytes are still the bzip2 magic "BZh", confirming the outer encoder produced a real bzip2 stream over the inner one.
# @timeout: 60
# @tags: usage, bzip2, pipeline, recompress
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
for i in range(80):
    sys.stdout.write("r15 double-compress row %03d alpha beta gamma\n" % i)
' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

# Double encode.
bzip2 -c "$tmpdir/in.txt" | bzip2 -c >"$tmpdir/double.bz2.bz2"

# The outer wrapper is a bzip2 stream too.
magic=$(head -c 3 "$tmpdir/double.bz2.bz2")
test "$magic" = "BZh"

# Double decode.
bunzip2 -c "$tmpdir/double.bz2.bz2" | bunzip2 -c >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
