#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch10-pax-binary-payload
# @title: python-libarchive-c pax binary payload
# @description: Writes a 64-byte binary payload into a pax archive via python-libarchive-c and verifies all bytes survive the round trip.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch10-pax-binary-payload"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write(path, entries, fmt="gnutar", filt=None):
    with libarchive.file_writer(str(path), fmt, filt) as writer:
        for name, data in entries.items():
            writer.add_file_from_memory(name, len(data), data)

def read(path):
    result = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            result[entry.pathname] = b"".join(entry.get_blocks())
    return result

def names(path):
    listed = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            listed.append(entry.pathname)
            b"".join(entry.get_blocks())
    return listed

def memory_read(payload):
    result = {}
    with libarchive.memory_reader(payload) as archive:
        for entry in archive:
            result[entry.pathname] = b"".join(entry.get_blocks())
    return result

def sizes(path):
    rows = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            rows.append((entry.pathname, entry.size))
            b"".join(entry.get_blocks())
    return rows

path = tmpdir / "binary.pax"
payload = bytes(range(64))
write(path, {"data.bin": payload}, fmt="pax")
assert read(path) == {"data.bin": payload}
print("pax-binary", len(payload))
PY
