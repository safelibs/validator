#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch10-zip-name-order-preserved
# @title: python-libarchive-c zip preserves write order
# @description: Writes three zip entries in non-alphabetical order via python-libarchive-c and verifies the reader returns them in the same insertion order.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch10-zip-name-order-preserved"
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

path = tmpdir / "ordered.zip"
ordered = ["zeta.txt", "alpha.txt", "mu.txt"]
expected = {name: f"value-{idx}\n".encode() for idx, name in enumerate(ordered)}
write(path, expected, fmt="zip")
listed = names(path)
assert listed == ordered, listed
print("zip-order")
PY
