#!/usr/bin/env bash
# @testcase: usage-bzip2-r18-decompress-uppercase-d-flag
# @title: bzip2 -d decompresses an archive in place and removes the .bz2 input
# @description: Compresses a small text payload with bzip2, runs bzip2 -d against the archive, and asserts the original filename exists with the original bytes restored while the .bz2 archive is gone — locking in the canonical in-place decompression contract.
# @timeout: 30
# @tags: usage, bzip2, decompress, r18
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

payload='alpha bravo charlie delta echo foxtrot'
printf '%s\n' "$payload" >"$tmpdir/data.txt"
expected_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')

bzip2 "$tmpdir/data.txt"

[[ -f "$tmpdir/data.txt.bz2" ]] || { printf 'expected archive at data.txt.bz2\n' >&2; exit 1; }
[[ ! -e "$tmpdir/data.txt" ]] || { printf 'expected original to be removed after compression\n' >&2; exit 1; }

bzip2 -d "$tmpdir/data.txt.bz2"

[[ -f "$tmpdir/data.txt" ]] || { printf 'expected data.txt to be restored\n' >&2; exit 1; }
[[ ! -e "$tmpdir/data.txt.bz2" ]] || { printf 'expected archive removed after decompression\n' >&2; exit 1; }

actual_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')
[[ "$actual_sha" == "$expected_sha" ]] || {
    printf 'sha mismatch: want=%s got=%s\n' "$expected_sha" "$actual_sha" >&2
    exit 1
}
