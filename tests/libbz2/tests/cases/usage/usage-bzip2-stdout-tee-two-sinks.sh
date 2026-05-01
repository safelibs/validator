#!/usr/bin/env bash
# @testcase: usage-bzip2-stdout-tee-two-sinks
# @title: bzip2 -c piped through tee
# @description: Streams bzip2 -c output through tee into two separate sinks and verifies both files are byte-identical and decompress back to the original payload.
# @timeout: 120
# @tags: usage, bzip2, pipeline
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-stdout-tee-two-sinks"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
for i in range(2000):
    sys.stdout.write("tee row %05d\n" % i)
' >"$tmpdir/in.txt"

bzip2 -c "$tmpdir/in.txt" | tee "$tmpdir/sink-a.bz2" >"$tmpdir/sink-b.bz2"
cmp "$tmpdir/sink-a.bz2" "$tmpdir/sink-b.bz2"
bzip2 -t "$tmpdir/sink-a.bz2"
bzip2 -t "$tmpdir/sink-b.bz2"
bunzip2 -c "$tmpdir/sink-b.bz2" >"$tmpdir/decoded.txt"
cmp "$tmpdir/in.txt" "$tmpdir/decoded.txt"
