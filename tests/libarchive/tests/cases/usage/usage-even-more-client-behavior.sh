#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

if case_id == 'usage-python-libarchive-c-memory-reader-cpio':
    path = tmpdir / 'data.cpio'
    expected = {'alpha.txt': b'alpha\n', 'beta.txt': b'beta\n'}
    write(path, expected, fmt='cpio')
    assert read_bytes(path.read_bytes()) == expected
    print('cpio-memory', len(expected))
elif case_id == 'usage-python-libarchive-c-memory-reader-pax':
    path = tmpdir / 'data.pax'
    expected = {'dir/pax.txt': b'pax payload\n'}
    write(path, expected, fmt='pax')
    assert read_bytes(path.read_bytes()) == expected
    print('pax-memory')
elif case_id == 'usage-python-libarchive-c-file-order-stable':
    path = tmpdir / 'order.tar'
    write(path, {'b.txt': b'b\n', 'a.txt': b'a\n', 'c.txt': b'c\n'})
    assert entry_names(path) == ['b.txt', 'a.txt', 'c.txt']
    print('order')
elif case_id == 'usage-python-libarchive-c-zip-spaced-name':
    path = tmpdir / 'space.zip'
    expected = {'dir/space name.txt': b'space zip\n'}
    write(path, expected, fmt='zip')
    assert read(path) == expected
    print('zip-space')
elif case_id == 'usage-python-libarchive-c-cpio-binary-payload':
    path = tmpdir / 'binary.cpio'
    payload = bytes(range(16))
    write(path, {'payload.bin': payload}, fmt='cpio')
    assert read(path) == {'payload.bin': payload}
    print('cpio-binary', len(payload))
elif case_id == 'usage-python-libarchive-c-pax-empty-file':
    path = tmpdir / 'empty.pax'
    write(path, {'empty.txt': b''}, fmt='pax')
    assert read(path) == {'empty.txt': b''}
    print('pax-empty')
elif case_id == 'usage-python-libarchive-c-zip-nul-bytes':
    path = tmpdir / 'nul.zip'
    payload = b'prefix\x00middle\x00suffix'
    write(path, {'nul.bin': payload}, fmt='zip')
    assert read(path)['nul.bin'] == payload
    print('zip-nul', len(payload))
elif case_id == 'usage-python-libarchive-c-zip-long-path':
    path = tmpdir / 'long.zip'
    expected = {'alpha/beta/gamma/delta/epsilon/long.txt': b'long zip path\n'}
    write(path, expected, fmt='zip')
    assert read(path) == expected
    print('zip-long')
elif case_id == 'usage-python-libarchive-c-add-entries-pax-to-zip':
    source = tmpdir / 'source.pax'
    target = tmpdir / 'target.zip'
    expected = {'alpha.txt': b'alpha\n', 'beta.txt': b'beta\n'}
    write(source, expected, fmt='pax')
    with libarchive.file_reader(str(source)) as entries, libarchive.file_writer(str(target), 'zip') as writer:
        writer.add_entries(entries)
    assert read(target) == expected
    print('pax-to-zip')
elif case_id == 'usage-python-libarchive-c-zip-many-empty-files':
    path = tmpdir / 'empty.zip'
    expected = {f'file-{i}.txt': b'' for i in range(6)}
    write(path, expected, fmt='zip')
    assert read(path) == expected
    print('zip-empty', len(expected))
else:
    raise SystemExit(f'unknown libarchive even-more usage case: {case_id}')
PY
