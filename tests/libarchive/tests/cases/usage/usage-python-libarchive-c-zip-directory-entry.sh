#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-zip-directory-entry
# @title: python-libarchive-c zip directory entry
# @description: Writes a zip archive with an explicit directory entry through python-libarchive-c and verifies the listed members.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-zip-directory-entry"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write(path, entries, fmt='gnutar', filt=None):
    with libarchive.file_writer(str(path), fmt, filt) as writer:
        for item in entries:
            name = item['name']
            data = item.get('data', b'')
            kwargs = {}
            if item.get('directory'):
                kwargs['filetype'] = 0o040000
                kwargs['permission'] = 0o755
            writer.add_file_from_memory(name, len(data), data, **kwargs)

def read(path):
    result = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            result[entry.pathname] = b''.join(entry.get_blocks())
    return result

def names(path):
    result = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            result.append(entry.pathname)
            b''.join(entry.get_blocks())
    return result

def memory_names(path):
    payload = path.read_bytes()
    result = []
    with libarchive.memory_reader(payload) as archive:
        for entry in archive:
            result.append(entry.pathname)
            b''.join(entry.get_blocks())
    return result

path = tmpdir / 'dir.zip'
write(path, [{'name': 'dir/', 'directory': True}, {'name': 'dir/nested.txt', 'data': b'nested\n'}], fmt='zip')
listed = names(path)
assert 'dir/' in listed and 'dir/nested.txt' in listed
print('zip-directory')
PYCASE
