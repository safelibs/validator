#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-tar-many-empty-files
# @title: python-libarchive-c tar many empty files
# @description: Writes and reads a tar archive containing several empty files through python-libarchive-c.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-tar-many-empty-files"
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

path = tmpdir / 'empty.tar'
expected = [{'name': f'empty-{index}.txt', 'data': b''} for index in range(5)]
write(path, expected)
assert read(path) == {item['name']: b'' for item in expected}
print('tar-many-empty')
PYCASE
