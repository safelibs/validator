#!/usr/bin/env bash
# @testcase: usage-bzip2recover-pieces-decompress-individually
# @title: bzip2recover pieces each decompress to a non-empty payload slice
# @description: Splits a multi-block bzip2 stream with bzip2recover, decompresses each piece on its own, and verifies every slice is non-empty and the concatenation in lexical order equals the original input byte-for-byte.
# @timeout: 300
# @tags: usage, bzip2recover, slicing
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "
import sys
for i in range(15000):
    sys.stdout.write(f'recover slice line {i:06d} payload-data\n')
" >"$tmpdir/in.txt"

bzip2 -1 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"

( cd "$tmpdir" && bzip2recover in.bz2 ) >"$tmpdir/recover.out" 2>&1

shopt -s nullglob
pieces=( "$tmpdir"/rec*in.bz2 )
shopt -u nullglob
if (( ${#pieces[@]} < 2 )); then
  printf 'expected at least 2 pieces, got %s\n' "${#pieces[@]}" >&2
  sed -n '1,40p' "$tmpdir/recover.out" >&2
  exit 1
fi

# Each piece must individually decompress to non-empty plaintext.
: >"$tmpdir/concat.txt"
for piece in "${pieces[@]}"; do
  bzip2 -t "$piece"
  bzip2 -dc "$piece" >"$tmpdir/piece.txt"
  size=$(wc -c <"$tmpdir/piece.txt")
  if (( size == 0 )); then
    printf 'piece %s decompressed to empty output\n' "$piece" >&2
    exit 1
  fi
  cat "$tmpdir/piece.txt" >>"$tmpdir/concat.txt"
done

# The lexical-order concatenation of decompressed pieces must equal the original.
cmp "$tmpdir/in.txt" "$tmpdir/concat.txt"

orig_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')
concat_sha=$(sha256sum "$tmpdir/concat.txt" | awk '{print $1}')
[[ "$orig_sha" == "$concat_sha" ]]
