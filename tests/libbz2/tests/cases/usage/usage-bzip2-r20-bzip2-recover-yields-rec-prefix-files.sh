#!/usr/bin/env bash
# @testcase: usage-bzip2-r20-bzip2-recover-yields-rec-prefix-files
# @title: bzip2recover on a valid archive produces files named rec*ARCHIVE*
# @description: Compresses a 4 KiB deterministic payload into a single archive, runs bzip2recover on the archive, and asserts at least one output file matches the canonical "rec*" naming pattern, exercising the recover utility's naming convention on a valid (non-corrupt) archive distinct from prior tests that asserted block-count or piece-cover behavior.
# @timeout: 30
# @tags: usage, bzip2recover, naming, r20
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
sys.stdout.buffer.write((b"r20-bzrecover-payload " * 256)[:4096])
' >"$tmpdir/src.bin"

bzip2 "$tmpdir/src.bin"
[[ -f "$tmpdir/src.bin.bz2" ]] || { printf 'no archive\n' >&2; exit 1; }

cd "$tmpdir"
bzip2recover src.bin.bz2 >"$tmpdir/rec.log" 2>&1 || true

count=$(ls -1 rec*src.bin.bz2 2>/dev/null | wc -l)
[[ "$count" -ge 1 ]] || {
    printf 'expected at least one rec*src.bin.bz2 piece, got %s\n' "$count" >&2
    ls -la "$tmpdir" >&2
    cat "$tmpdir/rec.log" >&2
    exit 1
}
