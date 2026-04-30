#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch16-threads-single
# @title: xz --threads=1 forced single-thread
# @description: Compresses a payload with xz --threads=1 to force single-thread encoding, then round-trips it through bsdcat.
# @timeout: 240
# @tags: usage, xz, threads
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a deterministic medium-sized payload so threading mode is non-trivial.
python3 -c 'import sys
for i in range(8192):
    sys.stdout.write(f"row {i:06d} alpha beta gamma delta\n")' >"$tmpdir/payload.txt"

src_sha=$(sha256sum "$tmpdir/payload.txt" | awk '{print $1}')

xz --threads=1 -z -k -c "$tmpdir/payload.txt" >"$tmpdir/payload.xz"

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/payload.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdcat "$tmpdir/payload.xz" >"$tmpdir/out.txt"
cmp "$tmpdir/payload.txt" "$tmpdir/out.txt"

out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
