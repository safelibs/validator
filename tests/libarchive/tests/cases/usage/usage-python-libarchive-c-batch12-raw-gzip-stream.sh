#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch12-raw-gzip-stream
# @title: python-libarchive-c raw gzip stream
# @description: Reads a plain gzip-compressed file using format_name="raw" through python-libarchive-c and verifies the payload bytes match.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch12-raw-gzip-stream"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

payload_path="$tmpdir/payload.bin"
gz_path="$tmpdir/payload.bin.gz"
python3 -c 'import sys; sys.stdout.buffer.write(b"raw payload bytes\n" * 64)' >"$payload_path"
gzip -c "$payload_path" >"$gz_path"

python3 - <<'PY' "$case_id" "$tmpdir" "$payload_path" "$gz_path"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
payload_path = Path(sys.argv[3])
gz_path = Path(sys.argv[4])

expected = payload_path.read_bytes()

decoded = b""
entry_count = 0
with libarchive.file_reader(str(gz_path), format_name="raw") as archive:
    for entry in archive:
        # libarchive's raw format yields a single synthetic "data" entry; the
        # block stream must be consumed inside this loop because advancing
        # past the entry puts the read pointer in 'eof' state.
        entry_count += 1
        decoded += b"".join(entry.get_blocks())
assert entry_count == 1, entry_count

assert decoded == expected, (len(decoded), len(expected))
print("raw-gzip", len(decoded))
PY
