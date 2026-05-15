#!/usr/bin/env bash
# @testcase: usage-vips-r19-avg-solid-32-jpeg
# @title: vips avg on a solid-32 grayscale JPEG returns a value close to 32
# @description: Encodes a 16x16 solid-gray-32 PGM as a grayscale JPEG via vips jpegsave then runs vips avg on it and asserts the printed numeric average is in the inclusive range [24, 40] (libjpeg-turbo quantisation drift around the original 32), exercising the vips avg reducer at a low-luma fixture distinct from r10/r17 mid-grey coverage.
# @timeout: 180
# @tags: usage, vips, jpeg, avg, low-luma, r19
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a solid-32 PGM via shell heredoc + dd for binary bytes.
{
  printf 'P5\n16 16\n255\n'
  head -c 256 /dev/zero | tr '\0' '\040' | tr '\040' '\040' >/dev/null
  # Emit 256 bytes of value 0x20 (32 decimal).
  head -c 256 </dev/zero | tr '\000' '\040'
} >"$tmpdir/in.pgm"

vips jpegsave "$tmpdir/in.pgm" "$tmpdir/in.jpg" --Q 95
raw=$(vips avg "$tmpdir/in.jpg")
val=${raw%%.*}
if (( val < 24 || val > 40 )); then
  printf 'expected avg in [24,40], got %s\n' "$raw" >&2
  exit 1
fi
