#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

if case_id == 'usage-python-libarchive-c-tar-dotfile':
    path = tmpdir / 'dot.tar'
    write(path, [{'name': '.hidden', 'data': b'hidden\n'}])
    assert read(path) == {'.hidden': b'hidden\n'}
    print('tar-dotfile')
elif case_id == 'usage-python-libarchive-c-zip-dotfile':
    path = tmpdir / 'dot.zip'
    write(path, [{'name': '.hidden', 'data': b'hidden\n'}], fmt='zip')
    assert read(path) == {'.hidden': b'hidden\n'}
    print('zip-dotfile')
elif case_id == 'usage-python-libarchive-c-tar-many-empty-files':
    path = tmpdir / 'empty.tar'
    expected = [{'name': f'empty-{index}.txt', 'data': b''} for index in range(5)]
    write(path, expected)
    assert read(path) == {item['name']: b'' for item in expected}
    print('tar-many-empty')
elif case_id == 'usage-python-libarchive-c-zip-directory-entry':
    path = tmpdir / 'dir.zip'
    write(path, [{'name': 'dir/', 'directory': True}, {'name': 'dir/nested.txt', 'data': b'nested\n'}], fmt='zip')
    listed = names(path)
    assert 'dir/' in listed and 'dir/nested.txt' in listed
    print('zip-directory')
elif case_id == 'usage-python-libarchive-c-cpio-empty-file':
    path = tmpdir / 'empty.cpio'
    write(path, [{'name': 'empty.txt', 'data': b''}], fmt='cpio')
    assert read(path) == {'empty.txt': b''}
    print('cpio-empty')
elif case_id == 'usage-python-libarchive-c-pax-directory-entry':
    path = tmpdir / 'dir.pax'
    write(path, [{'name': 'tree/', 'directory': True}, {'name': 'tree/value.txt', 'data': b'value\n'}], fmt='pax')
    listed = names(path)
    assert 'tree/' in listed and 'tree/value.txt' in listed
    print('pax-directory')
elif case_id == 'usage-python-libarchive-c-memory-reader-zip-directory':
    path = tmpdir / 'memory.zip'
    write(path, [{'name': 'dir/', 'directory': True}, {'name': 'dir/child.txt', 'data': b'child\n'}], fmt='zip')
    assert memory_names(path) == ['dir/', 'dir/child.txt']
    print('memory-reader-zip-directory')
elif case_id == 'usage-python-libarchive-c-tar-subdir-order':
    path = tmpdir / 'ordered.tar'
    write(path, [
        {'name': 'dir/a.txt', 'data': b'a\n'},
        {'name': 'dir/b.txt', 'data': b'b\n'},
        {'name': 'dir/c.txt', 'data': b'c\n'},
    ])
    assert names(path) == ['dir/a.txt', 'dir/b.txt', 'dir/c.txt']
    print('tar-subdir-order')
elif case_id == 'usage-python-libarchive-c-zip-nested-directory':
    path = tmpdir / 'nested.zip'
    expected = {'alpha/beta/value.txt': b'nested\n'}
    write(path, [{'name': name, 'data': data} for name, data in expected.items()], fmt='zip')
    assert read(path) == expected
    print('zip-nested-directory')
elif case_id == 'usage-python-libarchive-c-tar-hidden-directory-file':
    path = tmpdir / 'hidden.tar'
    expected = {'.config/value.txt': b'config\n'}
    write(path, [{'name': name, 'data': data} for name, data in expected.items()])
    assert read(path) == expected
    print('tar-hidden-directory-file')
else:
    raise SystemExit(f'unknown libarchive further usage case: {case_id}')
PYCASE
