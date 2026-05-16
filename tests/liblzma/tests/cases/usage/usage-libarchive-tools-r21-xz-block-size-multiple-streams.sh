#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r21-xz-block-size-multiple-streams
# @title: xz --block-size produces a multi-block .xz that decompresses round-trip
# @description: Builds a 64 KiB payload, compresses with --block-size=8KiB to force multiple internal blocks, decompresses, and asserts the result matches the original; verifies xz robot list reports multiple blocks via the totals row.
# @timeout: 60
# @tags: usage, xz, block-size, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 64 KiB of deterministic content
python3 - "$tmpdir/in.bin" <<'PY'
import sys
data = ('abcdefghijklmnopqrstuvwxyz0123456789' * 2000)[:65536]
open(sys.argv[1], 'wb').write(data.encode())
PY
sha_in=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

xz -k --block-size=8KiB "$tmpdir/in.bin"
validator_require_file "$tmpdir/in.bin.xz"

xz --robot -l "$tmpdir/in.bin.xz" >"$tmpdir/list.txt"
# totals row begins with "totals", block count is column 3
blocks=$(awk '$1=="totals"{print $3}' "$tmpdir/list.txt")
[[ "${blocks:-0}" -gt 1 ]] || { cat "$tmpdir/list.txt" >&2; echo "expected >1 block, got $blocks" >&2; exit 1; }

xz -d -k -c "$tmpdir/in.bin.xz" >"$tmpdir/out.bin"
sha_out=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
[[ "$sha_in" == "$sha_out" ]]
