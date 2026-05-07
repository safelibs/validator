#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r13-preset-levels-1-and-9
# @title: xz preset levels -1 and -9 each roundtrip identically and -9 is no larger
# @description: Compresses the same 256KB compressible payload at xz -1 and xz -9 separately, asserts both stream sha256 round-trip back to source, and that the level-9 archive is no larger than the level-1 archive on this compressible content.
# @timeout: 120
# @tags: usage, xz, preset, levels
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
chunk = b"the quick brown fox jumps over the lazy dog xyz\n"
sys.stdout.buffer.write(chunk * (256 * 1024 // len(chunk) + 1))
' >"$tmpdir/in.bin"

src_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

xz -1 -c "$tmpdir/in.bin" >"$tmpdir/out1.xz"
xz -9 -c "$tmpdir/in.bin" >"$tmpdir/out9.xz"

# Both decode roundtrip.
xz -d -c "$tmpdir/out1.xz" >"$tmpdir/d1.bin"
xz -d -c "$tmpdir/out9.xz" >"$tmpdir/d9.bin"
test "$src_sha" = "$(sha256sum "$tmpdir/d1.bin" | awk '{print $1}')"
test "$src_sha" = "$(sha256sum "$tmpdir/d9.bin" | awk '{print $1}')"

s1=$(stat -c '%s' "$tmpdir/out1.xz")
s9=$(stat -c '%s' "$tmpdir/out9.xz")
[[ "$s9" -le "$s1" ]] || {
    printf 'expected -9 (%d) <= -1 (%d)\n' "$s9" "$s1" >&2
    exit 1
}
