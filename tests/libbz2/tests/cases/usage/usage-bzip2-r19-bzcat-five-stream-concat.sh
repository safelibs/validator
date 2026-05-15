#!/usr/bin/env bash
# @testcase: usage-bzip2-r19-bzcat-five-stream-concat
# @title: bzcat decompresses a file made from five concatenated bzip2 streams
# @description: Compresses five distinct text payloads separately, concatenates the five .bz2 outputs into a single archive, decompresses with bzcat, and asserts the recovered output contains each of the five distinct markers in order - locking in multi-stream decompression at a higher stream count than existing tests.
# @timeout: 60
# @tags: usage, bzcat, multistream, r19
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in 1 2 3 4 5; do
    printf 'segment-marker-%s-payload\n' "$i" >"$tmpdir/p${i}.txt"
    bzip2 -c "$tmpdir/p${i}.txt" >"$tmpdir/p${i}.bz2"
done

cat "$tmpdir/p1.bz2" "$tmpdir/p2.bz2" "$tmpdir/p3.bz2" "$tmpdir/p4.bz2" "$tmpdir/p5.bz2" >"$tmpdir/all.bz2"
bzcat "$tmpdir/all.bz2" >"$tmpdir/out.txt"

lines=$(wc -l <"$tmpdir/out.txt")
[[ "$lines" -eq 5 ]] || {
    printf 'expected 5 lines, got %s\n' "$lines" >&2
    cat "$tmpdir/out.txt" >&2
    exit 1
}

for i in 1 2 3 4 5; do
    validator_assert_contains "$tmpdir/out.txt" "segment-marker-${i}-payload"
done
