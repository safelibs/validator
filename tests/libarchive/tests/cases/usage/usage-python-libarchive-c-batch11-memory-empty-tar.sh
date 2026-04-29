#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch11-memory-empty-tar
# @title: libarchive memory empty tar
# @description: Reads an empty tar member through python-libarchive-c memory_reader.
# @timeout: 180
# @tags: usage, python, archive
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch11-memory-empty-tar"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
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
    out = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            out[entry.pathname] = b"".join(entry.get_blocks())
    return out

def names(path):
    out = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            out.append(entry.pathname)
            b"".join(entry.get_blocks())
    return out

def memory_read(path):
    out = {}
    with libarchive.memory_reader(path.read_bytes()) as archive:
        for entry in archive:
            out[entry.pathname] = b"".join(entry.get_blocks())
    return out

def sizes(path):
    out = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            out[entry.pathname] = entry.size
            b"".join(entry.get_blocks())
    return out

path = tmpdir / "empty.tar"
expected = {"empty.txt": b""}
write(path, expected)
assert memory_read(path) == expected
print("memory-empty")
PYCASE
