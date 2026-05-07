#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r12-cli-rm-after-decode
# @title: zstd -d --rm removes the .zst source after a successful decode
# @description: Compresses an input, then decodes with --rm and asserts the source .zst file is removed while the recovered plaintext exists and matches the original byte stream.
# @timeout: 60
# @tags: usage, zstd, cli, rm
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'rm-after-decode payload row\n%.0s' {1..200} >"$tmpdir/orig.txt"
cp "$tmpdir/orig.txt" "$tmpdir/in.txt"

zstd -q "$tmpdir/in.txt" -o "$tmpdir/in.txt.zst"
rm -f "$tmpdir/in.txt"

# After --rm, the .zst should be gone and the .txt restored.
zstd -dq --rm "$tmpdir/in.txt.zst"

[[ ! -e "$tmpdir/in.txt.zst" ]] || {
    printf 'expected source .zst to be removed by --rm\n' >&2
    exit 1
}
validator_require_file "$tmpdir/in.txt"
cmp "$tmpdir/in.txt" "$tmpdir/orig.txt"
