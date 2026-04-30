#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch16-7z-readback-format-hint
# @title: python-libarchive-c 7z readback with explicit format_name hint
# @description: Writes a 7z archive via python-libarchive-c file_writer, then re-reads it through memory_reader using an explicit format_name="7zip" hint (rather than auto-detection), confirming the named-format reader path returns the same entries and payloads.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch16-7z-readback-format-hint"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "explicit.7z"
expected = {
    "docs/readme.txt": b"7zip explicit format hint\n",
    "docs/notes.txt": b"another 7z entry payload\n",
    "data/blob.bin": bytes(range(256)) * 4,
}
with libarchive.file_writer(str(archive_path), "7zip") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

# 7z signature is "7z\xBC\xAF\x27\x1C".
blob = archive_path.read_bytes()
assert blob[:6] == b"7z\xbc\xaf\x27\x1c", blob[:6]

# Re-read via memory_reader with an explicit format_name; this exercises the
# non-auto-detect read path.
got = {}
with libarchive.memory_reader(blob, format_name="7zip") as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == expected, sorted(got.keys())
print("7zip-explicit-hint", len(got))
PY
