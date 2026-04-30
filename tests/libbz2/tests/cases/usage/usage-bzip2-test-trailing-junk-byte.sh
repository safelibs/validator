#!/usr/bin/env bash
# @testcase: usage-bzip2-test-trailing-junk-byte
# @title: bzip2 -t rejects a stream with a corrupted internal byte
# @description: Flips an internal byte inside a valid bzip2 compressed stream and verifies bzip2 -t reports an integrity / corruption error rather than silently accepting the tampered file.
# @timeout: 180
# @tags: usage, bzip2, negative
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-test-trailing-junk-byte"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# A reasonably long payload so flipping a mid-stream byte lands inside
# the compressed Huffman-coded block rather than in the trailer.
python3 -c '
import sys
for i in range(2048):
    sys.stdout.write("bzip2 corruption probe line %d\n" % i)
' >"$tmpdir/in.txt"

bzip2 -c "$tmpdir/in.txt" >"$tmpdir/clean.bz2"
# Confirm the clean stream itself passes -t.
bzip2 -t "$tmpdir/clean.bz2"

# Mutate exactly one byte ~halfway through the compressed payload. Skip the
# 4-byte header so we keep the file looking like a bzip2 file at a glance.
clean_size=$(wc -c <"$tmpdir/clean.bz2")
cp "$tmpdir/clean.bz2" "$tmpdir/dirty.bz2"
python3 - "$tmpdir/dirty.bz2" <<'PY'
import sys
path = sys.argv[1]
with open(path, "r+b") as fh:
    data = bytearray(fh.read())
    # pick an offset inside the compressed body
    pos = max(8, len(data) // 2)
    data[pos] ^= 0xFF
    fh.seek(0)
    fh.write(data)
PY
dirty_size=$(wc -c <"$tmpdir/dirty.bz2")
[[ "$dirty_size" -eq "$clean_size" ]] || {
  printf 'expected dirty=%d clean=%d to be the same size\n' "$dirty_size" "$clean_size" >&2
  exit 1
}

if bzip2 -t "$tmpdir/dirty.bz2" >"$tmpdir/out" 2>"$tmpdir/err"; then
  printf 'bzip2 -t unexpectedly accepted a stream with a flipped byte\n' >&2
  exit 1
fi
test -s "$tmpdir/err"
grep -qiE 'data integrity|integrity|corrupt|not a bzip2 file' "$tmpdir/err" || {
  printf 'unexpected stderr for corrupted stream:\n' >&2
  cat "$tmpdir/err" >&2
  exit 1
}
