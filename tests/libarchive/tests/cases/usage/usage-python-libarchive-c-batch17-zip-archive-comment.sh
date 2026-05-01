#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch17-zip-archive-comment
# @title: python-libarchive-c zip with end-of-central-directory comment
# @description: Writes a small zip archive via libarchive.file_writer, then patches the trailing end-of-central-directory record to include a non-empty archive-level comment string, and feeds the modified bytes back through libarchive.memory_reader. Verifies that libarchive locates the EOCD past the trailing comment and still recovers every member intact, exercising the EOCD scan-back logic.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch17-zip-archive-comment"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import struct
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "comment.zip"
expected = {
    "alpha.txt": b"alpha zip comment payload\n",
    "beta.txt": b"beta zip comment payload\n",
}
with libarchive.file_writer(str(archive_path), "zip") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = bytearray(archive_path.read_bytes())
# EOCD signature is "PK\x05\x06" followed by 18 bytes of fixed fields.
sig = b"PK\x05\x06"
idx = raw.rfind(sig)
assert idx >= 0, raw[-64:]
# comment_len is the 2-byte little-endian field 20 bytes after the signature.
comment_len_off = idx + 20
existing = struct.unpack("<H", raw[comment_len_off:comment_len_off + 2])[0]
assert existing == 0, existing

comment = b"libarchive validator: archive comment for round 7\n"
raw[comment_len_off:comment_len_off + 2] = struct.pack("<H", len(comment))
raw.extend(comment)
patched = bytes(raw)

# Confirm our patched archive still reads correctly through libarchive.
got = {}
with libarchive.memory_reader(patched) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == expected, sorted(got.keys())
print("zip-comment", len(patched), len(comment))
PY
