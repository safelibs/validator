#!/usr/bin/env bash
# @testcase: usage-gzip-r20-decimal-level-fast
# @title: gzip --fast and gzip --best both produce valid gzip output for the same input
# @description: Compresses a 4 KiB repeating-pattern payload with gzip --fast and gzip --best independently, then asserts both outputs decompress to the original payload byte-for-byte and both files start with the gzip magic bytes 1f 8b - locking in libc-backed compression-level handling on both ends of the gzip level range.
# @timeout: 60
# @tags: usage, gzip, level, fast, best, r20
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 4 KiB of a repeating pattern (compresses well at all levels).
python3 -c 'import sys; sys.stdout.buffer.write((b"abcdefgh" * 512))' >"$tmpdir/in.bin"
[[ "$(wc -c <"$tmpdir/in.bin")" -eq 4096 ]] || { echo 'fixture wrong size' >&2; exit 1; }

gzip --fast -c "$tmpdir/in.bin" >"$tmpdir/fast.gz"
gzip --best -c "$tmpdir/in.bin" >"$tmpdir/best.gz"

for arc in fast.gz best.gz; do
    magic=$(head -c2 "$tmpdir/$arc" | od -An -tx1 | tr -d ' \n')
    [[ "$magic" == "1f8b" ]] || {
        printf 'expected gzip magic 1f8b for %s, got %s\n' "$arc" "$magic" >&2
        exit 1
    }
    gzip -dc "$tmpdir/$arc" >"$tmpdir/${arc}.out"
    cmp -s "$tmpdir/in.bin" "$tmpdir/${arc}.out" || {
        printf '%s roundtrip mismatch\n' "$arc" >&2
        exit 1
    }
done
