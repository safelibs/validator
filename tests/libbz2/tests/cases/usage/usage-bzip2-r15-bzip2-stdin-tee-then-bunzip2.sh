#!/usr/bin/env bash
# @testcase: usage-bzip2-r15-bzip2-stdin-tee-then-bunzip2
# @title: bzip2 stdin compression piped through tee to a file decompresses cleanly
# @description: Pipes a payload through "bzip2 -c", through "tee" (writing the compressed bytes to a sidecar file as well as forwarding them), into "bunzip2 -c" on the other end of the pipe. Asserts both the on-disk tee'd .bz2 and the in-line decoded stdout produce the same byte-equivalent recovered payload sha256 — exercising bzip2 as both ends of a tee'd shell pipeline.
# @timeout: 60
# @tags: usage, bzip2, pipeline, tee
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
for i in range(150):
    sys.stdout.write("r15 tee-pipeline row %03d alpha\n" % i)
' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 -c "$tmpdir/in.txt" | tee "$tmpdir/sidecar.bz2" | bunzip2 -c >"$tmpdir/inline.txt"

inline_sha=$(sha256sum "$tmpdir/inline.txt" | awk '{print $1}')
test "$src_sha" = "$inline_sha"

# Sidecar file independently round-trips back to the source.
bunzip2 -c "$tmpdir/sidecar.bz2" >"$tmpdir/sidecar.txt"
sidecar_sha=$(sha256sum "$tmpdir/sidecar.txt" | awk '{print $1}')
test "$src_sha" = "$sidecar_sha"
