#!/usr/bin/env bash
# @testcase: usage-bzcat-preserves-exact-line-count
# @title: bzcat preserves the exact source line count
# @description: Builds a source file with a known number of newline-terminated lines, compresses it with bzip2, and verifies bzcat decompression yields exactly the same line count plus the same final-newline status as the source - guarding against off-by-one or trailing-newline drift in the decompression path.
# @timeout: 180
# @tags: usage, bzcat, line-count
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

expected_lines=12345

python3 -c "
import sys
n = $expected_lines
for i in range(n):
    sys.stdout.write(f'line {i:06d} of fixed corpus\n')
" >"$tmpdir/in.txt"

# wc -l counts newline-terminated lines.
src_lines=$(wc -l <"$tmpdir/in.txt")
[[ "$src_lines" -eq "$expected_lines" ]] || {
  printf 'expected %s source lines, got %s\n' "$expected_lines" "$src_lines" >&2
  exit 1
}

# Last byte must be a newline (full-line corpus).
last_byte=$(tail -c 1 "$tmpdir/in.txt" | od -An -tu1 | tr -d ' \n')
[[ "$last_byte" == "10" ]] || {
  printf 'expected source to end with newline (10), got byte %s\n' "$last_byte" >&2
  exit 1
}

bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
bzcat "$tmpdir/in.txt.bz2" >"$tmpdir/out.txt"

out_lines=$(wc -l <"$tmpdir/out.txt")
[[ "$out_lines" -eq "$expected_lines" ]] || {
  printf 'bzcat output line count mismatch: source=%s, decompressed=%s\n' \
    "$expected_lines" "$out_lines" >&2
  exit 1
}

# Trailing-newline status must match.
out_last_byte=$(tail -c 1 "$tmpdir/out.txt" | od -An -tu1 | tr -d ' \n')
[[ "$out_last_byte" == "10" ]] || {
  printf 'bzcat output lost trailing newline: last byte %s\n' "$out_last_byte" >&2
  exit 1
}

# Byte-for-byte equality is the strongest possible check; do that too.
cmp "$tmpdir/in.txt" "$tmpdir/out.txt"
