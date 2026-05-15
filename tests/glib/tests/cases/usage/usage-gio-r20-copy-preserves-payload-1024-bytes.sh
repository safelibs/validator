#!/usr/bin/env bash
# @testcase: usage-gio-r20-copy-preserves-payload-1024-bytes
# @title: gio copy on a 1024-byte file preserves payload exactly via cmp
# @description: Creates a 1024-byte file with pseudo-random deterministic content from /dev/urandom (captured once), copies it via gio copy to a sibling path, and asserts the destination is byte-for-byte equal to the source with cmp, exercising the bulk-copy fidelity of gio copy for a non-trivial payload size distinct from prior empty/small/single-byte cases.
# @timeout: 60
# @tags: usage, gio, copy, payload, r20
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Deterministic 1024-byte content derived from a constant seed
python3 -c '
import sys
data = bytes((i * 7 + 13) & 0xff for i in range(1024))
sys.stdout.buffer.write(data)
' >"$tmpdir/src.bin"

src_size=$(stat -c '%s' "$tmpdir/src.bin")
[[ "$src_size" == "1024" ]] || { printf 'src size %s\n' "$src_size" >&2; exit 1; }

gio copy "$tmpdir/src.bin" "$tmpdir/dst.bin"
cmp "$tmpdir/src.bin" "$tmpdir/dst.bin"

dst_size=$(stat -c '%s' "$tmpdir/dst.bin")
[[ "$dst_size" == "1024" ]] || { printf 'dst size %s\n' "$dst_size" >&2; exit 1; }
