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

if case_id == "usage-python-libarchive-c-batch11-memory-empty-tar":
    path = tmpdir / "empty.tar"
    expected = {"empty.txt": b""}
    write(path, expected)
    assert memory_read(path) == expected
    print("memory-empty")
elif case_id == "usage-python-libarchive-c-batch11-tar-large-blocks":
    path = tmpdir / "large.tar"
    payload = (b"archive-block-" * 8192)
    write(path, {"large.bin": payload})
    assert read(path)["large.bin"] == payload
    print("large", len(payload))
elif case_id == "usage-python-libarchive-c-batch11-zip-crlf-payload":
    path = tmpdir / "crlf.zip"
    payload = b"alpha\r\nbeta\r\n"
    write(path, {"notes.txt": payload}, fmt="zip")
    assert read(path)["notes.txt"] == payload
    print("crlf")
elif case_id == "usage-python-libarchive-c-batch11-cpio-name-order":
    path = tmpdir / "ordered.cpio"
    expected = {"first.txt": b"1", "second.txt": b"2", "third.txt": b"3"}
    write(path, expected, fmt="cpio")
    assert names(path) == list(expected)
    print("cpio-order")
elif case_id == "usage-python-libarchive-c-batch11-pax-size-map":
    path = tmpdir / "sizes.pax"
    expected = {"zero.dat": b"", "five.dat": b"12345"}
    write(path, expected, fmt="pax")
    assert sizes(path) == {"zero.dat": 0, "five.dat": 5}
    print("sizes")
elif case_id == "usage-python-libarchive-c-batch11-tar-leading-dir":
    path = tmpdir / "dir.tar"
    expected = {"root/child/file.txt": b"child payload"}
    write(path, expected)
    assert read(path) == expected
    print("leading-dir")
elif case_id == "usage-python-libarchive-c-batch11-zip-json-payload":
    path = tmpdir / "json.zip"
    payload = b'{"alpha":1,"beta":[2,3]}\n'
    write(path, {"data.json": payload}, fmt="zip")
    assert read(path)["data.json"] == payload
    print("json")
elif case_id == "usage-python-libarchive-c-batch11-gzip-two-entries":
    path = tmpdir / "two.tar.gz"
    expected = {"a.txt": b"alpha\n", "b.txt": b"beta\n"}
    write(path, expected, filt="gzip")
    assert read(path) == expected
    print("gzip-two")
elif case_id == "usage-python-libarchive-c-batch11-bzip2-memory-reader":
    path = tmpdir / "mem.tar.bz2"
    expected = {"payload.txt": b"bzip2 memory reader\n"}
    write(path, expected, filt="bzip2")
    assert memory_read(path) == expected
    print("bzip2-memory")
elif case_id == "usage-python-libarchive-c-batch11-zstd-size-check":
    path = tmpdir / "size.tar.zst"
    expected = {"zstd.txt": b"zstd payload"}
    write(path, expected, filt="zstd")
    assert sizes(path)["zstd.txt"] == len(expected["zstd.txt"])
    print("zstd-size")
else:
    raise SystemExit(f"unknown libarchive eleventh-batch usage case: {case_id}")
PYCASE
