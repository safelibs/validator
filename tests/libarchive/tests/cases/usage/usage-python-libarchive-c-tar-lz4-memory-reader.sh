#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-tar-lz4-memory-reader
# @title: python-libarchive-c tar lz4 memory reader
# @description: Reads an lz4-filtered gnutar archive from memory through python-libarchive-c and verifies entry payloads.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-tar-lz4-memory-reader"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "input.tar.lz4"
expected = {
    "items/red.txt": b"red lz4 payload\n",
    "items/green.txt": b"green lz4 payload\n",
    "items/blue.txt": b"blue lz4 payload\n",
}
with libarchive.file_writer(str(archive_path), "gnutar", "lz4") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

# lz4 frame magic is 0x184D2204 little-endian.
head = archive_path.read_bytes()[:4]
assert head == b"\x04\x22\x4d\x18", f"unexpected lz4 header bytes: {head!r}"

received = {}
with libarchive.memory_reader(archive_path.read_bytes()) as archive:
    for entry in archive:
        received[entry.pathname] = b"".join(entry.get_blocks())

assert received == expected, sorted(received)
print("tar-lz4-memory", len(received))
PY
