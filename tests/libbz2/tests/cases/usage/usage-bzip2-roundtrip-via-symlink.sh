#!/usr/bin/env bash
# @testcase: usage-bzip2-roundtrip-via-symlink
# @title: bzip2 round trip via symlink target
# @description: Points a symlink at a real file and verifies bzip2 -c through the symlink reads the target's bytes and produces a stream that decompresses back to the original payload.
# @timeout: 180
# @tags: usage, bzip2, symlink
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-roundtrip-via-symlink"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Real payload lives in a sibling directory so the symlink is unambiguous.
mkdir -p "$tmpdir/real"
python3 -c "import sys
for i in range(32):
    sys.stdout.write(f'symlink target payload {i}\n')" >"$tmpdir/real/data.txt"

ln -s "$tmpdir/real/data.txt" "$tmpdir/link.txt"
[[ -L "$tmpdir/link.txt" ]] || {
  printf 'symlink was not created\n' >&2
  exit 1
}

# bzip2 -c on the symlink path follows the link and reads the target bytes.
bzip2 -c "$tmpdir/link.txt" >"$tmpdir/link.txt.bz2"
validator_require_file "$tmpdir/link.txt.bz2"

# Decompressing must yield the exact target payload.
bzip2 -dc "$tmpdir/link.txt.bz2" >"$tmpdir/round.txt"
cmp "$tmpdir/real/data.txt" "$tmpdir/round.txt"

# The symlink itself must still resolve to the original target file.
[[ -L "$tmpdir/link.txt" ]]
target=$(readlink "$tmpdir/link.txt")
[[ "$target" == "$tmpdir/real/data.txt" ]] || {
  printf 'symlink target unexpectedly changed: %s\n' "$target" >&2
  exit 1
}
