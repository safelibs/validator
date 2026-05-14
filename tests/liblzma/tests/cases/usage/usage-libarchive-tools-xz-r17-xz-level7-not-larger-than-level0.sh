#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r17-xz-level7-not-larger-than-level0
# @title: xz -7 output size does not exceed xz -0 output size on a repetitive payload
# @description: Compresses the same repetitive payload at xz -0 and xz -7 and asserts the level-7 output is <= the level-0 output, exercising the preset compression-ratio monotonicity on a representative input.
# @timeout: 60
# @tags: usage, xz, level, size
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.buffer.write((b'r17-level-cmp-' * 1024))" >"$tmpdir/in.txt"

xz -0 -c "$tmpdir/in.txt" >"$tmpdir/lvl0.xz"
xz -7 -c "$tmpdir/in.txt" >"$tmpdir/lvl7.xz"

size0=$(stat -c '%s' "$tmpdir/lvl0.xz")
size7=$(stat -c '%s' "$tmpdir/lvl7.xz")

[[ "$size7" -le "$size0" ]] || {
  printf 'expected level-7 <= level-0, got %s > %s\n' "$size7" "$size0" >&2
  exit 1
}
