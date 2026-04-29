#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch10-tar-zstd-memory-reader
# @title: python-libarchive-c tar zstd memory reader
# @description: Writes a zstd-filtered tar via python-libarchive-c and verifies memory_reader returns both entries with their payloads.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch10-tar-zstd-memory-reader"
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

path = tmpdir / "zstd.tar.zst"
expected = {"alpha.txt": b"alpha\n", "beta.txt": b"beta\n"}
write(path, expected, filt="zstd")
assert memory_read(path.read_bytes()) == expected
print("zstd-memory")
PY
