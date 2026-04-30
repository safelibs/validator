#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-cpio-bzip2-filter
# @title: python-libarchive-c cpio bzip2 filter
# @description: Roundtrips a bzip2-filtered cpio archive through python-libarchive-c.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-cpio-bzip2-filter"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write(path, entries, fmt="cpio", filt=None):
    with libarchive.file_writer(str(path), fmt, filt) as writer:
        for name, data in entries.items():
            writer.add_file_from_memory(name, len(data), data)

def read(path):
    result = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            result[entry.pathname] = b"".join(entry.get_blocks())
    return result

path = tmpdir / "data.cpio.bz2"
expected = {
    "note.txt": b"cpio bzip2 note\n",
    "log.txt": b"cpio bzip2 log\n",
}
write(path, expected, fmt="cpio", filt="bzip2")

# bzip2 stream magic 'BZh'
head = path.read_bytes()[:3]
assert head == b"BZh", f"unexpected bzip2 header bytes: {head!r}"

assert read(path) == expected
print("cpio-bzip2", len(expected))
PY
