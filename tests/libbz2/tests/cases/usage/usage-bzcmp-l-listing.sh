#!/usr/bin/env bash
# @testcase: usage-bzcmp-l-listing
# @title: bzcmp -l lists every differing byte
# @description: Compresses two same-length payloads with several known differing byte positions and verifies bzcmp -l prints one line per differing byte at the expected 1-indexed offsets, with the differing byte values rendered in octal.
# @timeout: 180
# @tags: usage, bzip2, compare, verbose
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Two 16-byte payloads differing at exactly 3 positions.
# offsets (0-indexed): 4, 9, 13. cmp -l reports 1-indexed: 5, 10, 14.
python3 -c 'open("'"$tmpdir"'/a.bin", "wb").write(b"AAAAAAAAAAAAAAAA")
open("'"$tmpdir"'/b.bin", "wb").write(b"AAAAB" + b"AAAA" + b"C" + b"AAA" + b"D" + b"AA")'

# Sanity: lengths must be equal and exactly three byte positions must differ.
[[ "$(wc -c <"$tmpdir/a.bin")" -eq 16 ]]
[[ "$(wc -c <"$tmpdir/b.bin")" -eq 16 ]]
diff_positions=$(python3 -c 'a=open("'"$tmpdir"'/a.bin","rb").read()
b=open("'"$tmpdir"'/b.bin","rb").read()
print(",".join(str(i+1) for i,(x,y) in enumerate(zip(a,b)) if x!=y))')
[[ "$diff_positions" == "5,10,14" ]] || {
  printf 'unexpected differing positions: %s\n' "$diff_positions" >&2
  exit 1
}

bzip2 -k "$tmpdir/a.bin"
bzip2 -k "$tmpdir/b.bin"

# bzcmp -l: list all differing bytes. Expected exit 1 (files differ).
set +e
bzcmp -l "$tmpdir/a.bin.bz2" "$tmpdir/b.bin.bz2" >"$tmpdir/out" 2>"$tmpdir/err"
rc=$?
set -e
[[ "$rc" -eq 1 ]] || {
  printf 'expected bzcmp -l exit 1, got %s\n' "$rc" >&2
  cat "$tmpdir/out" "$tmpdir/err" >&2 || true
  exit 1
}

# Each differing byte must produce its own listing line, with the 1-indexed
# offset as the first whitespace-separated column.
listed=$(awk '{print $1}' "$tmpdir/out" | tr '\n' ',' | sed 's/,$//')
[[ "$listed" == "5,10,14" ]] || {
  printf 'expected bzcmp -l offsets 5,10,14, got %s\n' "$listed" >&2
  cat "$tmpdir/out" >&2
  exit 1
}

# cmp -l renders the differing bytes in octal; 'A'=0101, 'B'=0102, 'C'=0103, 'D'=0104.
# Verify at least one expected octal pair appears in the output.
validator_assert_contains "$tmpdir/out" '101'
validator_assert_contains "$tmpdir/out" '102'
