#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r15-cli-no-check-listing
# @title: zstd --no-check produces a frame whose -lv listing reports Check: None
# @description: Compresses a payload with zstd --no-check so the trailing XXH64 checksum is suppressed, runs zstd -lv on the result, and asserts the verbose listing reports a "Check: None" row (vs. "Check: XXH64" for a default frame). Also confirms decompression still recovers the source byte-for-byte.
# @timeout: 60
# @tags: usage, archive, zstd, cli, checksum
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r15 no-check listing row\n" * 1500)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

zstd -q --no-check -o "$tmpdir/nc.zst" "$src"
zstd -lv "$tmpdir/nc.zst" >"$tmpdir/nc.listing" 2>&1

grep -E 'Check:[[:space:]]+None' "$tmpdir/nc.listing" >/dev/null || {
    printf 'expected Check: None for --no-check frame\n' >&2
    cat "$tmpdir/nc.listing" >&2
    exit 1
}

# Sanity contrast: default frame lists XXH64.
zstd -q -o "$tmpdir/def.zst" "$src"
zstd -lv "$tmpdir/def.zst" >"$tmpdir/def.listing" 2>&1
grep -E 'Check:[[:space:]]+XXH64' "$tmpdir/def.listing" >/dev/null || {
    printf 'expected Check: XXH64 on default frame\n' >&2
    cat "$tmpdir/def.listing" >&2
    exit 1
}

zstd -dq -c "$tmpdir/nc.zst" >"$tmpdir/decoded.bin"
test "$src_sum" = "$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')"
