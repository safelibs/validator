#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r12-cli-stdout-flag-c
# @title: zstd -c writes the compressed frame to stdout without touching the source
# @description: Runs zstd -c to encode a file to stdout, captures the bytes via shell redirection, and asserts the source file is preserved on disk while the captured stdout decodes cleanly back to the original payload.
# @timeout: 60
# @tags: usage, zstd, cli, stdout
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r12 -c stdout payload row\n%.0s' {1..400} >"$tmpdir/in.txt"
src_sum=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

zstd -q -c "$tmpdir/in.txt" >"$tmpdir/captured.zst"

# Source file must remain on disk; no auto-removal without --rm.
validator_require_file "$tmpdir/in.txt"

magic=$(od -An -N4 -tx1 "$tmpdir/captured.zst" | tr -d ' \n')
[[ "$magic" == "28b52ffd" ]] || {
    printf 'expected zstd magic in captured stdout, got %s\n' "$magic" >&2
    exit 1
}

zstd -dq "$tmpdir/captured.zst" -o "$tmpdir/decoded.txt"
dst_sum=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
[[ "$src_sum" == "$dst_sum" ]] || {
    printf 'sha256 mismatch after stdout round-trip\n' >&2
    exit 1
}
