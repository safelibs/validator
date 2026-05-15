#!/usr/bin/env bash
# @testcase: usage-bzip2-r19-bzcmp-equal-files-rc0
# @title: bzcmp reports identical content with exit 0 across two distinct compression levels
# @description: Compresses the same plain payload twice (level -1 and level -9) into separately-named .bz2 archives, runs bzcmp on the pair, and asserts the exit status is 0 with empty stdout - locking in compression-level-agnostic equality on decompressed content.
# @timeout: 30
# @tags: usage, bzcmp, equality, r19
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/base.txt" <<'PY'
import sys
with open(sys.argv[1], 'w') as f:
    for i in range(256):
        f.write(f"line-{i:03d}-words and more words here\n")
PY

cp "$tmpdir/base.txt" "$tmpdir/a"
cp "$tmpdir/base.txt" "$tmpdir/b"
bzip2 -1 "$tmpdir/a"
bzip2 -9 "$tmpdir/b"

out=$(bzcmp "$tmpdir/a.bz2" "$tmpdir/b.bz2")
[[ -z "$out" ]] || {
    printf 'expected empty stdout, got: %s\n' "$out" >&2
    exit 1
}
