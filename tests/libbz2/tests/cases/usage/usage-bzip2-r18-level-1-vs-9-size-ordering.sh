#!/usr/bin/env bash
# @testcase: usage-bzip2-r18-level-1-vs-9-size-ordering
# @title: bzip2 -1 and bzip2 -9 produce archives where level 9 is no larger than level 1
# @description: Generates a moderately compressible 64 KiB payload of repeated structured text, compresses two copies at -1 and -9 respectively, and asserts level-9 size is less than or equal to level-1 size — locking in the monotonicity of higher levels never being worse on compressible input.
# @timeout: 60
# @tags: usage, bzip2, level, size, r18
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 64 KiB of repeating compressible content.
python3 - "$tmpdir/in.txt" <<'PY'
import sys
with open(sys.argv[1], 'w') as f:
    for i in range(2048):
        f.write(f"line-{i:04d}-the-quick-brown-fox-jumps-over-the-lazy-dog\n")
PY

cp "$tmpdir/in.txt" "$tmpdir/a"
cp "$tmpdir/in.txt" "$tmpdir/b"
bzip2 -1 "$tmpdir/a"
bzip2 -9 "$tmpdir/b"

s1=$(wc -c <"$tmpdir/a.bz2")
s9=$(wc -c <"$tmpdir/b.bz2")
[[ "$s9" -le "$s1" ]] || {
    printf 'expected level-9 (%s) <= level-1 (%s)\n' "$s9" "$s1" >&2
    exit 1
}
