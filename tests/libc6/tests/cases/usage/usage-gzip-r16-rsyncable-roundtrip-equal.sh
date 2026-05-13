#!/usr/bin/env bash
# @testcase: usage-gzip-r16-rsyncable-roundtrip-equal
# @title: gzip --rsyncable produces a stream that round-trips to identical bytes
# @description: Compresses a payload with gzip --rsyncable and asserts the decompressed bytes equal the original byte-for-byte, locking in that the rsyncable block-boundary heuristic does not alter the payload content even though it changes the compressed representation.
# @timeout: 60
# @tags: usage, gzip, rsyncable
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "
import sys
sys.stdout.write(('alpha bravo charlie delta\n' * 2048))
" >"$tmpdir/payload.txt"

expected=$(sha256sum "$tmpdir/payload.txt" | awk '{print $1}')
gzip --rsyncable -c "$tmpdir/payload.txt" >"$tmpdir/out.gz"
gunzip -c "$tmpdir/out.gz" >"$tmpdir/decoded.txt"
got=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
[[ "$expected" == "$got" ]]
