#!/usr/bin/env bash
# @testcase: usage-gzip-r21-stdout-keep-source-and-compressed
# @title: gzip -c writes a valid archive to stdout while leaving the source file intact
# @description: Writes a payload, pipes it through gzip -c into a separate .gz, decompresses to verify integrity, and asserts both the source still exists at original size and the decompressed payload matches the source - locking in gzip -c stdout mode's non-destructive behavior on the source distinct from existing keep-flag tests.
# @timeout: 30
# @tags: usage, gzip, stdout, keep, r21
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'payload-r21-gzip\n' >"$tmpdir/src.txt"
src_size=$(stat -c '%s' "$tmpdir/src.txt")

gzip -c "$tmpdir/src.txt" >"$tmpdir/out.gz"

# Source unchanged
[[ -f "$tmpdir/src.txt" ]] || { echo 'source removed' >&2; exit 1; }
new_size=$(stat -c '%s' "$tmpdir/src.txt")
[[ "$new_size" -eq "$src_size" ]] || { printf 'source size changed: %s -> %s\n' "$src_size" "$new_size" >&2; exit 1; }

# .gz round-trip preserves content
gzip -dc "$tmpdir/out.gz" >"$tmpdir/back.txt"
cmp -s "$tmpdir/src.txt" "$tmpdir/back.txt" || {
    echo 'roundtrip mismatch' >&2
    exit 1
}
