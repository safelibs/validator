#!/usr/bin/env bash
# @testcase: usage-bzip2-r21-bzip2recover-rec-files-decode-individually
# @title: bzip2recover output recXXXX files each decode under bzip2 -t
# @description: Builds a multi-block archive by compressing a 1MB random payload at -9 -1 block size, runs bzip2recover, and asserts each resulting recXXXX.bz2 file passes bzip2 -t independently - locking in the per-block recovery file integrity contract (existing recover tests check piece count or pieces-cover-payload but not per-piece -t pass).
# @timeout: 120
# @tags: usage, bzip2recover, integrity, r21
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 1MB random payload compressed at -1 block size yields multiple bzip2 blocks.
dd if=/dev/urandom of="$tmpdir/orig.bin" bs=1024 count=1024 status=none
bzip2 -1 -c "$tmpdir/orig.bin" >"$tmpdir/archive.bz2"

(cd "$tmpdir" && bzip2recover "archive.bz2" >/dev/null 2>&1)

pieces=$(ls "$tmpdir"/rec*archive.bz2 2>/dev/null | wc -l)
[[ "$pieces" -ge 2 ]] || { printf 'expected at least 2 rec pieces, got %s\n' "$pieces" >&2; exit 1; }

for f in "$tmpdir"/rec*archive.bz2; do
    bzip2 -t "$f" || { printf 'piece %s failed bzip2 -t\n' "$f" >&2; exit 1; }
done
