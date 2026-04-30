#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-no-progress
# @title: zstd CLI --no-progress suppresses progress counter
# @description: Compresses a payload with 'zstd --no-progress' to forcibly hide the progress counter even when stderr is a terminal-like context, verifies the resulting frame still carries the zstd magic, passes integrity testing, decodes byte-for-byte to the source, and confirms stderr does not contain the carriage-return-driven progress redraw markers (\r) that the counter normally emits.
# @timeout: 120
# @tags: usage, archive, zstd, cli, progress
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"no-progress payload chunk row\n" * 4096)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

# Run zstd with --no-progress and capture stderr. Do not pass -q here so that
# any progress counter would otherwise be free to print.
zstd --no-progress -o "$tmpdir/out.zst" "$src" 2>"$tmpdir/err.log"
validator_require_file "$tmpdir/out.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/out.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$tmpdir/out.zst"
zstd -dq -c "$tmpdir/out.zst" >"$tmpdir/decoded.bin"
cmp "$src" "$tmpdir/decoded.bin"

dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

# The progress counter is rendered with \r redraws; --no-progress must suppress
# them. Banner/summary text is allowed.
if grep -q $'\r' "$tmpdir/err.log"; then
  printf '--no-progress did not suppress \\r progress redraws\n' >&2
  od -c "$tmpdir/err.log" | sed -n '1,40p' >&2
  exit 1
fi
