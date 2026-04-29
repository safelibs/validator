#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch10-zip-deep-path
# @title: python-libarchive-c zip deep nested path
# @description: Writes a six-segment nested pathname into a zip via python-libarchive-c and verifies the full path survives the round trip.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch10-zip-deep-path"
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

path = tmpdir / "deep.zip"
expected = {"a/b/c/d/e/f/leaf.txt": b"deep zip payload\n"}
write(path, expected, fmt="zip")
got = read(path)
assert got == expected, got
print("zip-deep")
PY
