#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r20-xz-level-9-not-larger-than-level-1
# @title: xz -9 compression of a 16 KiB repetitive payload is not larger than xz -1
# @description: Generates a 16 KiB highly-repetitive payload, compresses it via xz -1 and xz -9 separately, and asserts the -9 output size is less than or equal to the -1 output size, pinning the level-9 preset's at-least-as-good compression contract on a redundant input.
# @timeout: 60
# @tags: usage, xz, level, size-monotonic, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.buffer.write((b'ABCDEFGH'*2048))" >"$tmpdir/in.bin"

xz -c -1 "$tmpdir/in.bin" >"$tmpdir/lo.xz"
xz -c -9 "$tmpdir/in.bin" >"$tmpdir/hi.xz"

s_lo=$(wc -c <"$tmpdir/lo.xz")
s_hi=$(wc -c <"$tmpdir/hi.xz")
if [[ "$s_hi" -gt "$s_lo" ]]; then
  printf 'expected -9 (%s) <= -1 (%s)\n' "$s_hi" "$s_lo" >&2
  exit 1
fi
