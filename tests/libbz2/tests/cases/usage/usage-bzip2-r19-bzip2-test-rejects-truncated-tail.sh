#!/usr/bin/env bash
# @testcase: usage-bzip2-r19-bzip2-test-rejects-truncated-tail
# @title: bzip2 -t rejects an archive whose final byte has been removed
# @description: Compresses a payload, truncates the archive by one byte from the tail, then runs bzip2 -t on the damaged file and asserts a non-zero exit code with the original (untruncated) archive still passing -t with rc 0 - locking in integrity detection of tail truncation.
# @timeout: 30
# @tags: usage, bzip2, test, truncation, r19
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.txt" <<'PY'
import sys
with open(sys.argv[1], 'w') as f:
    for i in range(200):
        f.write(f"row {i:03d} payload data goes here for compression\n")
PY

bzip2 -c "$tmpdir/in.txt" >"$tmpdir/good.bz2"
size=$(stat -c '%s' "$tmpdir/good.bz2")
truncated=$((size - 1))
dd if="$tmpdir/good.bz2" of="$tmpdir/bad.bz2" bs=1 count="$truncated" status=none

bzip2 -t "$tmpdir/good.bz2"

set +e
bzip2 -t "$tmpdir/bad.bz2" >"$tmpdir/err.log" 2>&1
rc=$?
set -e

[[ "$rc" -ne 0 ]] || {
    printf 'expected bzip2 -t to reject truncated archive, got rc=0\n' >&2
    cat "$tmpdir/err.log" >&2
    exit 1
}
