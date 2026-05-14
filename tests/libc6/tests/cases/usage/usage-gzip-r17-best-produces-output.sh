#!/usr/bin/env bash
# @testcase: usage-gzip-r17-best-produces-output
# @title: gzip --best emits a smaller-or-equal archive than --fast for compressible input
# @description: Compresses the same large repetitive payload twice — once with --fast and once with --best — and asserts the --best archive is at most as large as the --fast archive while decompressing back to the original SHA-256, locking in the level-9 effectiveness contract.
# @timeout: 60
# @tags: usage, gzip, level
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "
import sys
for i in range(20000):
    sys.stdout.write('compressible repetitive line alpha bravo charlie delta echo\n')
" >"$tmpdir/payload.txt"
want=$(sha256sum "$tmpdir/payload.txt" | awk '{print $1}')

gzip --fast -c "$tmpdir/payload.txt" >"$tmpdir/fast.gz"
gzip --best -c "$tmpdir/payload.txt" >"$tmpdir/best.gz"

fast_size=$(wc -c <"$tmpdir/fast.gz")
best_size=$(wc -c <"$tmpdir/best.gz")
[[ "$best_size" -le "$fast_size" ]] || {
    printf 'expected --best (%s) <= --fast (%s)\n' "$best_size" "$fast_size" >&2
    exit 1
}

got=$(gzip -dc "$tmpdir/best.gz" | sha256sum | awk '{print $1}')
[[ "$want" == "$got" ]] || {
    printf 'sha256 mismatch after gzip --best roundtrip\n' >&2
    exit 1
}
