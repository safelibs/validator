#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch13-deb-as-ar-archive
# @title: python-libarchive-c read .deb as ar archive
# @description: Builds a minimal ar (.deb-style) archive containing the standard debian-binary, control.tar, and data.tar member names via python-libarchive-c then reads it back, asserting libarchive auto-detects the ar format and exposes all three member names.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch13-deb-as-ar-archive"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

path = tmpdir / "fake.deb"
members = {
    "debian-binary": b"2.0\n",
    # Use ".tar" suffixes (not .gz) so libarchive doesn't try to decompress
    # what is in fact a small placeholder payload.
    "control.tar": b"\x00" * 1024,
    "data.tar": b"DATA-PAYLOAD" + b"\x00" * 100,
}
with libarchive.file_writer(str(path), "ar_bsd") as writer:
    for name, data in members.items():
        writer.add_file_from_memory(name, len(data), data)

blob = path.read_bytes()
assert blob.startswith(b"!<arch>\n"), blob[:16]

found = {}
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        found[entry.pathname] = b"".join(entry.get_blocks())

# ar member names may be padded/trimmed; compare on stripped names.
got_names = sorted(name.rstrip("/ ") for name in found)
assert got_names == sorted(members.keys()), got_names
# Confirm the data payload is preserved for at least the data.tar member,
# which is the part a real .deb consumer would care about.
data_key = next(k for k in found if k.rstrip("/ ") == "data.tar")
assert found[data_key] == members["data.tar"], (len(found[data_key]), len(members["data.tar"]))
print("deb-ar", got_names)
PY
