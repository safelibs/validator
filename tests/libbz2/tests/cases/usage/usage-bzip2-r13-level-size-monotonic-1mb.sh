#!/usr/bin/env bash
# @testcase: usage-bzip2-r13-level-size-monotonic-1mb
# @title: bzip2 -1 produces a no-smaller archive than -9 on 1MB compressible input
# @description: Compresses a 1 MiB highly-repetitive payload at levels -1 and -9 separately and asserts the level-9 output is no larger than the level-1 output (typically strictly smaller for compressible content), capturing the documented level-vs-size relationship.
# @timeout: 90
# @tags: usage, bzip2, levels
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 1 MiB of highly compressible content (repeated 32-byte block).
python3 -c '
import sys
chunk = b"abcdefghijklmnopqrstuvwxyz012345"
sys.stdout.buffer.write(chunk * (1024 * 1024 // len(chunk)))
' >"$tmpdir/in.bin"

bzip2 -1 -c "$tmpdir/in.bin" >"$tmpdir/out1.bz2"
bzip2 -9 -c "$tmpdir/in.bin" >"$tmpdir/out9.bz2"

s1=$(stat -c '%s' "$tmpdir/out1.bz2")
s9=$(stat -c '%s' "$tmpdir/out9.bz2")

# Both must be valid bz2 streams.
bzip2 -t "$tmpdir/out1.bz2"
bzip2 -t "$tmpdir/out9.bz2"

# Level 9 is no larger than level 1 on this compressible input.
[[ "$s9" -le "$s1" ]] || {
    printf 'expected -9 (%d) <= -1 (%d)\n' "$s9" "$s1" >&2
    exit 1
}
