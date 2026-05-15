#!/usr/bin/env bash
# @testcase: usage-bzip2-r20-bzip2-decompress-keep-archive-with-d-uppercase
# @title: bzip2 -dk decompresses while keeping the source archive intact and recovers payload
# @description: Compresses a payload, then runs bzip2 -dk on the archive to decompress while keeping the archive (-k), and asserts both the original archive and the decompressed plain file are present after the operation with the plain file content matching the source - exercising the combination of the keep flag with the lowercase-d decompress flag in a single short-option cluster -dk distinct from the r18 in-place -d test that removes the archive.
# @timeout: 30
# @tags: usage, bzip2, decompress, keep, r20
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r20 -dk payload\nsecond line\n' >"$tmpdir/src.txt"
cp "$tmpdir/src.txt" "$tmpdir/orig.txt"
bzip2 "$tmpdir/src.txt"
[[ -f "$tmpdir/src.txt.bz2" && ! -f "$tmpdir/src.txt" ]] || {
    printf 'unexpected compress state\n' >&2; ls -la "$tmpdir" >&2; exit 1
}

bzip2 -dk "$tmpdir/src.txt.bz2"

[[ -f "$tmpdir/src.txt.bz2" ]] || { printf 'expected archive preserved by -k\n' >&2; exit 1; }
[[ -f "$tmpdir/src.txt" ]] || { printf 'expected decompressed file present\n' >&2; exit 1; }

diff "$tmpdir/orig.txt" "$tmpdir/src.txt"
