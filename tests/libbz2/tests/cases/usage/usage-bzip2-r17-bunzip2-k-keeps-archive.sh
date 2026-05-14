#!/usr/bin/env bash
# @testcase: usage-bzip2-r17-bunzip2-k-keeps-archive
# @title: bunzip2 -k retains the .bz2 archive alongside the decompressed output
# @description: Compresses a payload then runs bunzip2 -k against the archive and asserts both the decompressed file and the original .bz2 archive exist afterward, locking in the keep-original flag for the decompression direction.
# @timeout: 60
# @tags: usage, bunzip2, keep
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r17 bunzip2 -k keep body\n' >"$tmpdir/payload.txt"
bzip2 "$tmpdir/payload.txt"
[[ -f "$tmpdir/payload.txt.bz2" ]]

bunzip2 -k "$tmpdir/payload.txt.bz2"

[[ -f "$tmpdir/payload.txt" ]] || {
    printf 'expected decompressed payload to exist\n' >&2
    exit 1
}
[[ -f "$tmpdir/payload.txt.bz2" ]] || {
    printf 'expected .bz2 archive to be kept after bunzip2 -k\n' >&2
    exit 1
}
validator_assert_contains "$tmpdir/payload.txt" 'r17 bunzip2 -k keep body'
