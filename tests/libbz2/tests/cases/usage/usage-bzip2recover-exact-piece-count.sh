#!/usr/bin/env bash
# @testcase: usage-bzip2recover-exact-piece-count
# @title: bzip2recover produces exactly the expected number of pieces
# @description: Compresses a payload large enough to span exactly N bzip2 -1 (100k) blocks, runs bzip2recover, and verifies the produced rec*.bz2 piece count equals N - matching the per-block stderr "block 1 to 1" line count emitted by bzip2recover.
# @timeout: 300
# @tags: usage, bzip2recover, piece-count
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Generate ~700 KiB of compressible-but-non-trivial text so bzip2 -1 emits multiple blocks.
python3 -c "
import sys
for i in range(20000):
    sys.stdout.write(f'recover piece line {i:06d} payload payload payload\n')
" >"$tmpdir/in.txt"

# Use level -1 (100k blocks) so a multi-block stream is produced.
bzip2 -1 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"

# Run bzip2recover; capture stderr so we can extract the per-block "block N" lines.
( cd "$tmpdir" && bzip2recover in.bz2 ) >"$tmpdir/recover.out" 2>"$tmpdir/recover.err"

# bzip2recover prints "writing block N to `recNNNNNin.bz2'" once per piece on stderr.
expected_blocks=$(grep -cE "^[[:space:]]*writing block [0-9]+ to " "$tmpdir/recover.err" || true)
[[ "$expected_blocks" -ge 2 ]] || {
  printf 'expected at least 2 blocks reported by bzip2recover, got %s\n' "$expected_blocks" >&2
  sed -n '1,80p' "$tmpdir/recover.err" >&2
  exit 1
}

shopt -s nullglob
pieces=( "$tmpdir"/rec*in.bz2 )
shopt -u nullglob
piece_count=${#pieces[@]}

[[ "$piece_count" -eq "$expected_blocks" ]] || {
  printf 'piece count mismatch: stderr blocks=%s, files on disk=%s\n' \
    "$expected_blocks" "$piece_count" >&2
  printf 'pieces:\n' >&2
  printf '  %s\n' "${pieces[@]}" >&2
  exit 1
}

# Each piece must itself decompress cleanly (well-formed individual blocks).
for piece in "${pieces[@]}"; do
  bzip2 -t "$piece"
done

# Sanity: concatenated pieces reproduce the original input.
cat "${pieces[@]}" >"$tmpdir/concat.bz2"
bzcat "$tmpdir/concat.bz2" >"$tmpdir/round.txt"
cmp "$tmpdir/in.txt" "$tmpdir/round.txt"
