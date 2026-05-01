#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch17-tar-null-payload-pattern
# @title: python-libarchive-c gnutar with all-zero payload region
# @description: Stores a regular file whose payload is a multi-kilobyte run of NUL bytes inside a gnutar archive. tar pads regular file content with NULs to the next 512-byte block, so an all-zero payload looks indistinguishable from inter-record padding. Verifies that libarchive's reader still surfaces exactly the original number of bytes (entry.size and concatenated get_blocks() length both equal the payload length).
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch17-tar-null-payload-pattern"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "zeros.tar"
zero_blob = b"\x00" * 8192
trailing = b"sentinel after zeros\n"
plan = {
    "zeros.bin": zero_blob,
    "after.txt": trailing,
}

with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    for name, body in plan.items():
        writer.add_file_from_memory(name, len(body), body)

records = []
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        data = b"".join(entry.get_blocks())
        records.append((entry.pathname, entry.size, data))

by_name = {n: (s, d) for n, s, d in records}
assert by_name["zeros.bin"][0] == len(zero_blob), by_name["zeros.bin"][0]
assert by_name["zeros.bin"][1] == zero_blob, len(by_name["zeros.bin"][1])
assert by_name["after.txt"][1] == trailing, by_name["after.txt"][1]
print("zero-payload", [(n, s) for n, s, _ in records])
PY
