#!/usr/bin/env bash
# @testcase: usage-bzip2-r20-bzip2-level-5-roundtrip-1mb
# @title: bzip2 at level -5 compresses and decompresses 1 MiB of structured data losslessly
# @description: Generates exactly 1 MiB of structured byte-pattern data, compresses it with bzip2 -5 -c, decompresses with bzip2 -dc, and asserts the recovered bytes equal the source via cmp - locking in a mid-range compression-level roundtrip distinct from prior tests that focus on -1, -2, -7, or -9.
# @timeout: 60
# @tags: usage, bzip2, level-5, roundtrip, r20
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
data = bytes((i * 13 + 7) & 0xff for i in range(1048576))
sys.stdout.buffer.write(data)
' >"$tmpdir/src.bin"

size=$(stat -c '%s' "$tmpdir/src.bin")
[[ "$size" == "1048576" ]] || { printf 'src size %s\n' "$size" >&2; exit 1; }

bzip2 -5 -c "$tmpdir/src.bin" >"$tmpdir/src.bin.bz2"
bzip2 -dc "$tmpdir/src.bin.bz2" >"$tmpdir/recovered.bin"

cmp "$tmpdir/src.bin" "$tmpdir/recovered.bin"
