#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch11-zstd-size-check
# @title: libarchive zstd size check
# @description: Checks zstd-filtered member size metadata through python-libarchive-c.
# @timeout: 180
# @tags: usage, python, archive
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch11-zstd-size-check"
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

path = tmpdir / "size.tar.zst"
expected = {"zstd.txt": b"zstd payload"}
write(path, expected, filt="zstd")
assert sizes(path)["zstd.txt"] == len(expected["zstd.txt"])
print("zstd-size")
PYCASE
