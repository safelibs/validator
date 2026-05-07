#!/usr/bin/env bash
# @testcase: usage-coreutils-r15-od-w-line-width
# @title: coreutils od -w16 controls bytes-per-line and emits the expected number of data rows
# @description: Generates a fixed 32-byte payload, runs od -An -tx1 -w16 under LC_ALL=C to dump the bytes in canonical 1-byte hex with a 16-byte line width, and asserts the output has exactly two non-empty data rows of sixteen 2-hex-digit tokens — exercising od's libc-backed buffered I/O and width formatting.
# @timeout: 60
# @tags: usage, coreutils, od, r15
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 32 distinct bytes spanning two 16-byte lines (so od does not collapse rows with '*').
LC_ALL=C printf 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345' >"$tmpdir/in.bin"
[[ "$(wc -c <"$tmpdir/in.bin")" -eq 32 ]]

LC_ALL=C od -An -tx1 -w16 "$tmpdir/in.bin" >"$tmpdir/got.txt"

# Trim blank lines and count.
data_lines=$(LC_ALL=C grep -cE '^[[:space:]]*[0-9a-f]{2}([[:space:]]+[0-9a-f]{2}){15}[[:space:]]*$' \
  "$tmpdir/got.txt")
[[ "$data_lines" -eq 2 ]]
