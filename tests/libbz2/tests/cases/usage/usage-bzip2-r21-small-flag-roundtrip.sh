#!/usr/bin/env bash
# @testcase: usage-bzip2-r21-small-flag-roundtrip
# @title: bzip2 -d -s small-mode decompresses a level-9 archive byte-for-byte
# @description: Compresses a 256KB payload with bzip2 -9, then decompresses with bzip2 -d -s (small/reduced-memory mode) into stdout and asserts the recovered bytes match the original SHA-256 - locking in the -s reduced-memory decompression code path which is distinct from the default decompressor.
# @timeout: 60
# @tags: usage, bzip2, small-mode, r21
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Make a 256KB pseudo-random payload (deterministic via head/tr fallback).
dd if=/dev/urandom of="$tmpdir/orig.bin" bs=1024 count=256 status=none
src_sha=$(sha256sum "$tmpdir/orig.bin" | awk '{print $1}')

bzip2 -9 -k "$tmpdir/orig.bin"
[[ -f "$tmpdir/orig.bin.bz2" ]] || { echo 'compressed file missing' >&2; exit 1; }

bzip2 -d -s -c "$tmpdir/orig.bin.bz2" >"$tmpdir/out.bin"
out_sha=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')

[[ "$out_sha" == "$src_sha" ]] || {
    printf 'sha256 mismatch: expected %s got %s\n' "$src_sha" "$out_sha" >&2
    exit 1
}
