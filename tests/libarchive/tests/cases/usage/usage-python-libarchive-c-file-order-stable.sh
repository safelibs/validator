#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-file-order-stable
# @title: python libarchive stable file order
# @description: Exercises python libarchive stable file order through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-file-order-stable"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write(path, entries, fmt='gnutar', filt=None):
    with libarchive.file_writer(str(path), fmt, filt) as writer:
        for name, data in entries.items():
            writer.add_file_from_memory(name, len(data), data)

def read(path):
    result = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            result[entry.pathname] = b''.join(entry.get_blocks())
    return result

def read_bytes(payload):
    result = {}
    with libarchive.memory_reader(payload) as archive:
        for entry in archive:
            result[entry.pathname] = b''.join(entry.get_blocks())
    return result

def entry_names(path):
    names = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            names.append(entry.pathname)
            b''.join(entry.get_blocks())
    return names

path = tmpdir / 'order.tar'
write(path, {'b.txt': b'b\n', 'a.txt': b'a\n', 'c.txt': b'c\n'})
assert entry_names(path) == ['b.txt', 'a.txt', 'c.txt']
print('order')
PY
