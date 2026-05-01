#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch17-raw-xz-stream
# @title: python-libarchive-c raw xz stream
# @description: Reads a plain xz-compressed file via libarchive.file_reader with format_name="raw" so libarchive treats the input as a single synthetic data entry decoded only through its xz filter chain. Verifies the decoded byte stream equals the original uncompressed payload, exercising the raw-format read path for the xz filter (distinct from the gzip and bzip2 raw paths covered by earlier batches).
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch17-raw-xz-stream"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

payload_path="$tmpdir/payload.bin"
xz_path="$tmpdir/payload.bin.xz"
python3 -c 'import sys; sys.stdout.buffer.write(b"raw xz payload bytes\n" * 96)' >"$payload_path"
xz -c -k "$payload_path" >"$xz_path"

python3 - <<'PY' "$case_id" "$payload_path" "$xz_path"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
payload_path = Path(sys.argv[2])
xz_path = Path(sys.argv[3])

expected = payload_path.read_bytes()

decoded = b""
entry_count = 0
with libarchive.file_reader(str(xz_path), format_name="raw") as archive:
    for entry in archive:
        entry_count += 1
        decoded += b"".join(entry.get_blocks())
assert entry_count == 1, entry_count
assert decoded == expected, (len(decoded), len(expected))
print("raw-xz", len(decoded))
PY
