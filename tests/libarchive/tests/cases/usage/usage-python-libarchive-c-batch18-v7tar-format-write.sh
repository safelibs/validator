#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch18-v7tar-format-write
# @title: python-libarchive-c v7tar format write
# @description: Writes a Version-7 Unix tar archive (libarchive format_name="v7tar"), the pre-ustar tar variant whose 512-byte header lacks the "ustar" magic and supports only the original short-name fields. Asserts the produced bytes are 512-byte block aligned, the first 6 bytes of the file (where ustar would carry "ustar\0") contain no ustar magic, and that read-back through libarchive.file_reader returns each member's payload byte-for-byte.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch18-v7tar-format-write"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "out.v7.tar"
expected = {
    "v7file.txt": b"v7tar payload alpha\n",
    "another.txt": b"v7tar payload beta\n",
}

with libarchive.file_writer(str(archive_path), "v7tar") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = archive_path.read_bytes()
# v7 tar uses the same 512-byte block alignment as later variants.
assert len(raw) % 512 == 0, len(raw)
# The "ustar" magic lives at offset 257 inside a 512-byte ustar header. v7tar
# pre-dates that field, so the bytes there must NOT contain the ustar magic.
first_header = raw[:512]
assert b"ustar" not in first_header[257:265], first_header[257:265]
# v7tar still terminates with two zero blocks like ustar; the trailing two
# 512-byte chunks must be all-NUL.
assert raw[-1024:] == b"\x00" * 1024, raw[-1024:][:32]

got = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == expected, (sorted(got.keys()), sorted(expected.keys()))
print("v7tar", len(raw), sorted(got.keys()))
PY
