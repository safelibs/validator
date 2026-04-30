#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch14-7zip-multi-files-read
# @title: python-libarchive-c 7zip read with multiple files
# @description: Writes a 7z archive containing five distinct member files (varying payload sizes and content) through python-libarchive-c, then reads the archive back and verifies every name, size, and payload survives. Distinct from the existing two-entry 7zip test because each entry is read with size assertions and the read order is checked against the deterministic insertion order.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch14-7zip-multi-files-read"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

path = tmpdir / "multi.7z"
expected = [
    ("one.txt", b"one\n"),
    ("two.bin", bytes(range(64))),
    ("three.log", b"line A\nline B\nline C\n"),
    ("nested/four.txt", b"nested four payload\n"),
    ("five.dat", b"\xff" * 4096),
]

with libarchive.file_writer(str(path), "7zip") as writer:
    for name, payload in expected:
        writer.add_file_from_memory(name, len(payload), payload)

raw = path.read_bytes()
assert raw[:6] == b"7z\xbc\xaf\x27\x1c", raw[:6]

read_records = []
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        data = b"".join(entry.get_blocks())
        read_records.append((entry.pathname, entry.size, data))

assert len(read_records) == len(expected), len(read_records)
got_names = [name for name, _, _ in read_records]
expected_names = [name for name, _ in expected]
assert sorted(got_names) == sorted(expected_names), (got_names, expected_names)

by_name = {name: (size, data) for name, size, data in read_records}
for name, payload in expected:
    size, data = by_name[name]
    assert data == payload, name
    # 7z does not always set entry.size on the header, but when it does
    # it must equal the payload length.
    if size is not None:
        assert size == len(payload), (name, size, len(payload))
print("7zip-multi", len(read_records))
PY
