#!/usr/bin/env bash
# @testcase: usage-bzip2recover-concatenate-pieces
# @title: bzip2recover pieces concatenate into the original stream
# @description: Splits a multi-block stream with bzip2recover, concatenates the rec*.bz2 fragments in lexical order, and verifies bzcat over the concatenation reproduces the original payload exactly.
# @timeout: 300
# @tags: usage, bzip2recover, concatenation
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2recover-concatenate-pieces"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Generate enough payload to span several -1 (100k) blocks.
python3 -c "import sys
for i in range(20000):
    sys.stdout.write(f'recover concat payload line {i:06d}\n')" >"$tmpdir/in.txt"

bzip2 -1 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"

# Run bzip2recover on the (uncorrupted) stream to split it into per-block pieces.
( cd "$tmpdir" && bzip2recover in.bz2 ) >"$tmpdir/recover.out" 2>&1

shopt -s nullglob
pieces=( "$tmpdir"/rec*in.bz2 )
shopt -u nullglob
if (( ${#pieces[@]} < 2 )); then
  printf 'expected at least 2 recovery pieces, got %d\n' "${#pieces[@]}" >&2
  sed -n '1,40p' "$tmpdir/recover.out" >&2
  exit 1
fi

# Concatenate pieces in lexical order; bzip2 streams are concatenable.
# The shell glob already expands in lexical order.
cat "${pieces[@]}" >"$tmpdir/concat.bz2"

# bzcat over the concatenation must reproduce the original payload byte-for-byte.
bzcat "$tmpdir/concat.bz2" >"$tmpdir/round.txt"
cmp "$tmpdir/in.txt" "$tmpdir/round.txt"
