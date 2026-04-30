#!/usr/bin/env bash
# @testcase: usage-bzip2recover-corrupt-pieces
# @title: bzip2recover salvages blocks from corrupted stream
# @description: Corrupts a multi-block bzip2 stream and verifies bzip2recover emits per-block rec*.bz2 fragments.
# @timeout: 240
# @tags: usage, recovery, negative
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a payload large enough to span multiple bzip2 blocks at -1 (100k blocks).
for i in $(seq 1 8000); do
  printf 'recover block payload line %05d\n' "$i"
done >"$tmpdir/in.txt"

bzip2 -1 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"

# Corrupt a wide chunk deep inside the stream, away from the header magic.
# A single-byte poke is not always enough to defeat bzip2's CRCs once the
# RLE/Huffman tables happen to absorb it, so zero a 32-byte run in the
# middle of the compressed payload.
size=$(wc -c <"$tmpdir/in.bz2")
[[ "$size" -gt 256 ]]
cp "$tmpdir/in.bz2" "$tmpdir/corrupt.bz2"
mid=$((size / 2))
dd if=/dev/zero of="$tmpdir/corrupt.bz2" bs=1 count=32 seek="$mid" conv=notrunc status=none

# A direct bzip2 -t must reject the corrupt stream.
if bzip2 -t "$tmpdir/corrupt.bz2" 2>"$tmpdir/test.err"; then
  printf 'corrupt stream unexpectedly passed bzip2 -t\n' >&2
  exit 1
fi

# bzip2recover must extract per-block fragment files.
( cd "$tmpdir" && bzip2recover corrupt.bz2 ) >"$tmpdir/recover.out" 2>&1 || true

shopt -s nullglob
pieces=( "$tmpdir"/rec*corrupt.bz2 )
shopt -u nullglob
if (( ${#pieces[@]} == 0 )); then
  printf 'bzip2recover produced no rec*.bz2 fragments\n' >&2
  sed -n '1,40p' "$tmpdir/recover.out" >&2
  exit 1
fi

# At least one fragment must itself be a valid bzip2 stream that decompresses.
recovered_any=0
for piece in "${pieces[@]}"; do
  if bzip2 -t "$piece" 2>/dev/null; then
    bzip2 -dc "$piece" >"$tmpdir/piece.out"
    if [[ -s "$tmpdir/piece.out" ]] && grep -q 'recover block payload' "$tmpdir/piece.out"; then
      recovered_any=1
      break
    fi
  fi
done
if (( recovered_any != 1 )); then
  printf 'no recovered fragment yielded original payload text\n' >&2
  exit 1
fi
