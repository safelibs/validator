#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r21-xz-delta-filter-roundtrip
# @title: xz delta filter chained with lzma2 round-trips a small payload
# @description: Compresses a payload with --delta=dist=1 chained to --lzma2=preset=6 and decompresses it back via xz -d, asserting the recovered SHA matches the original input, pinning the delta-then-lzma2 filter-chain support in the liblzma CLI.
# @timeout: 60
# @tags: usage, xz, delta-filter, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# A monotonic byte payload that benefits from delta=1
python3 - "$tmpdir/in.bin" <<'PY'
import sys
open(sys.argv[1], 'wb').write(bytes((i & 0xff) for i in range(0, 4096)))
PY
sha_in=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

xz --format=raw --delta=dist=1 --lzma2=preset=6 -c "$tmpdir/in.bin" >"$tmpdir/raw.bin"
xz -d --format=raw --delta=dist=1 --lzma2=preset=6 -c "$tmpdir/raw.bin" >"$tmpdir/out.bin"
sha_out=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
[[ "$sha_in" == "$sha_out" ]]
