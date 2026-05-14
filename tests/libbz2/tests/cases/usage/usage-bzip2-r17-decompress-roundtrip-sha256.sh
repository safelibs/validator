#!/usr/bin/env bash
# @testcase: usage-bzip2-r17-decompress-roundtrip-sha256
# @title: bzip2 -d roundtrip preserves the SHA-256 of the original payload
# @description: Compresses a multi-line payload with bzip2 then decompresses it via bzip2 -d and asserts the SHA-256 of the recovered file equals the SHA-256 of the original, locking in a content-addressed integrity contract beyond a plain byte-diff.
# @timeout: 60
# @tags: usage, bzip2, sha256, roundtrip
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "
import sys
for i in range(2000):
    sys.stdout.write(f'r17 sha256 line {i} alpha bravo charlie delta echo foxtrot\n')
" >"$tmpdir/payload.txt"

want=$(sha256sum "$tmpdir/payload.txt" | awk '{print $1}')

bzip2 -c "$tmpdir/payload.txt" >"$tmpdir/payload.bz2"
rm "$tmpdir/payload.txt"
bzip2 -d "$tmpdir/payload.bz2"

got=$(sha256sum "$tmpdir/payload.txt" | awk '{print $1}')
[[ "$want" == "$got" ]] || {
    printf 'sha256 mismatch: want=%s got=%s\n' "$want" "$got" >&2
    exit 1
}
