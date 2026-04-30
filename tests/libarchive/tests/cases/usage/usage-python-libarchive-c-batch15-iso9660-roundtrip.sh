#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch15-iso9660-roundtrip
# @title: python-libarchive-c iso9660 write+read roundtrip
# @description: Writes an iso9660 archive containing two regular files via python-libarchive-c file_writer, then reads it back and verifies entry pathnames and payloads roundtrip. iso9660 uppercases pathnames and may emit additional Joliet/Rockridge directory shadows, so the assertion compares against a normalised (uppercased, basename-only) view of the entries.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch15-iso9660-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import os
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

iso_path = tmpdir / "out.iso"
entries = {
    "ALPHA.TXT": b"alpha payload bytes\n",
    "BETA.TXT": b"beta payload more bytes\n",
}

with libarchive.file_writer(str(iso_path), "iso9660") as writer:
    for name, data in entries.items():
        writer.add_file_from_memory(name, len(data), data)

# iso9660 image must be a multiple of 2048 and start with the system area
# (32768 zero bytes) before the Volume Descriptor at sector 16.
size = iso_path.stat().st_size
assert size % 2048 == 0, size
with iso_path.open("rb") as fh:
    fh.seek(32768 + 1)
    vd_id = fh.read(5)
assert vd_id == b"CD001", vd_id

# Read back; iso9660 reader prefixes paths with the volume layout so we
# only check that every basename uppercased shows up with the matching
# payload. A plain regular-file entry filter excludes the directory shells.
got = {}
with libarchive.file_reader(str(iso_path)) as archive:
    for entry in archive:
        data = b"".join(entry.get_blocks())
        if not entry.isreg:
            continue
        base = os.path.basename(entry.pathname.rstrip("/")).upper()
        # Joliet/Rockridge can emit the same basename twice with identical
        # data. Stable to compare the last seen entry.
        got[base] = data

for name, payload in entries.items():
    assert name in got, (name, sorted(got))
    assert got[name] == payload, (name, len(got[name]), len(payload))
print("iso9660", sorted(got))
PY
