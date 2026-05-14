#!/usr/bin/env bash
# @testcase: usage-bzip2-r17-bzip2recover-valid-archive
# @title: bzip2recover writes per-block rec*.bz2 fragments for an intact archive
# @description: Compresses a large payload so the resulting .bz2 contains several blocks, runs bzip2recover against the intact archive (no truncation), and asserts at least one rec*.bz2 fragment is produced — exercising the block-extraction path on a healthy archive rather than a corrupted one.
# @timeout: 120
# @tags: usage, bzip2recover, valid
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "
import sys
for i in range(120000):
    sys.stdout.write(f'r17 valid recover line {i} alpha bravo charlie delta echo foxtrot golf hotel india\n')
" >"$tmpdir/payload.txt"
bzip2 -1 -c "$tmpdir/payload.txt" >"$tmpdir/payload.bz2"

cd "$tmpdir"
bzip2recover "$tmpdir/payload.bz2" >"$tmpdir/recover.out" 2>"$tmpdir/recover.err" || true

shopt -s nullglob
matches=("$tmpdir"/rec*.bz2)
shopt -u nullglob
[[ "${#matches[@]}" -ge 1 ]] || {
    printf 'expected at least one rec*.bz2 fragment from valid archive\n' >&2
    ls -la "$tmpdir" >&2
    cat "$tmpdir/recover.err" >&2
    exit 1
}
