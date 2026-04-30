#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch15-raw-bz2-stream
# @title: python-libarchive-c raw bzip2 stream
# @description: Writes a plain bzip2-compressed file with the system bzip2 tool, then reads it through python-libarchive-c using format_name="raw" so libarchive yields the synthetic single "data" entry. Drains the entry via entry.get_blocks() inside the iteration loop (raw format requires the block stream be consumed before advancing) and verifies the decompressed payload bytes match the original.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch15-raw-bz2-stream"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

payload_path="$tmpdir/payload.bin"
bz_path="$tmpdir/payload.bin.bz2"
python3 -c 'import sys; sys.stdout.buffer.write(b"raw bzip2 stream payload bytes\n" * 64)' >"$payload_path"
bzip2 -c "$payload_path" >"$bz_path"

# Sanity: confirm the system tool emitted a real bzip2 stream before we hand
# it to libarchive.
head_bytes=$(head -c 3 "$bz_path" | od -An -c | tr -d ' \n')
[[ "$head_bytes" == "BZh" ]] || {
    printf 'unexpected bz2 header: %s\n' "$head_bytes" >&2
    exit 1
}

python3 - <<'PY' "$case_id" "$tmpdir" "$payload_path" "$bz_path"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
payload_path = Path(sys.argv[3])
bz_path = Path(sys.argv[4])

expected = payload_path.read_bytes()

decoded = b""
entry_count = 0
with libarchive.file_reader(str(bz_path), format_name="raw") as archive:
    for entry in archive:
        # raw format yields a single synthetic "data" entry; the block
        # stream must be drained inside the loop before the iterator
        # advances past EOF.
        entry_count += 1
        decoded += b"".join(entry.get_blocks())
assert entry_count == 1, entry_count
assert decoded == expected, (len(decoded), len(expected))
print("raw-bz2", len(decoded))
PY
