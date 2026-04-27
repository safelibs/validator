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

if case_id == "usage-python-libarchive-c-batch10-tar-gzip-roundtrip":
    path = tmpdir / "gz.tar.gz"
    expected = {"gz.txt": b"gzip filter payload\n"}
    write(path, expected, filt="gzip")
    assert read(path) == expected
    print("gzip-roundtrip")
elif case_id == "usage-python-libarchive-c-batch10-zip-deep-path":
    path = tmpdir / "deep.zip"
    expected = {"a/b/c/d/e/f/leaf.txt": b"deep zip payload\n"}
    write(path, expected, fmt="zip")
    got = read(path)
    assert got == expected, got
    print("zip-deep")
elif case_id == "usage-python-libarchive-c-batch10-tar-many-empties":
    path = tmpdir / "many-empties.tar"
    expected = {f"empty-{i}.txt": b"" for i in range(7)}
    write(path, expected)
    got = read(path)
    assert got == expected, got
    print("tar-many-empties", len(expected))
elif case_id == "usage-python-libarchive-c-batch10-pax-binary-payload":
    path = tmpdir / "binary.pax"
    payload = bytes(range(64))
    write(path, {"data.bin": payload}, fmt="pax")
    assert read(path) == {"data.bin": payload}
    print("pax-binary", len(payload))
elif case_id == "usage-python-libarchive-c-batch10-cpio-binary-roundtrip":
    path = tmpdir / "binary.cpio"
    payload = b"\x00\xff\x10\xab" * 16
    write(path, {"binary.bin": payload}, fmt="cpio")
    assert read(path)["binary.bin"] == payload
    print("cpio-binary", len(payload))
elif case_id == "usage-python-libarchive-c-batch10-zip-bzip2-filter-fallback":
    path = tmpdir / "bz.tar.bz2"
    expected = {"bz.txt": b"bzip2 deeply nested payload\n"}
    write(path, expected, filt="bzip2")
    listed = sorted(names(path))
    assert listed == ["bz.txt"]
    print("bzip2-fallback")
elif case_id == "usage-python-libarchive-c-batch10-tar-zstd-memory-reader":
    path = tmpdir / "zstd.tar.zst"
    expected = {"alpha.txt": b"alpha\n", "beta.txt": b"beta\n"}
    write(path, expected, filt="zstd")
    assert memory_read(path.read_bytes()) == expected
    print("zstd-memory")
elif case_id == "usage-python-libarchive-c-batch10-zip-name-order-preserved":
    path = tmpdir / "ordered.zip"
    ordered = ["zeta.txt", "alpha.txt", "mu.txt"]
    expected = {name: f"value-{idx}\n".encode() for idx, name in enumerate(ordered)}
    write(path, expected, fmt="zip")
    listed = names(path)
    assert listed == ordered, listed
    print("zip-order")
elif case_id == "usage-python-libarchive-c-batch10-tar-size-zero-mixed":
    path = tmpdir / "mixed.tar"
    expected = {
        "first.txt": b"",
        "second.txt": b"abc\n",
        "third.txt": b"",
        "fourth.txt": b"xyz\n",
    }
    write(path, expected)
    rows = sizes(path)
    by_name = {name: size for name, size in rows}
    assert by_name == {"first.txt": 0, "second.txt": 4, "third.txt": 0, "fourth.txt": 4}, by_name
    print("size-mixed")
elif case_id == "usage-python-libarchive-c-batch10-zip-large-payload":
    path = tmpdir / "large.zip"
    payload = (b"zip-large-payload-" * 2048)
    write(path, {"large.bin": payload}, fmt="zip")
    assert read(path)["large.bin"] == payload
    print("zip-large", len(payload))
else:
    raise SystemExit(f"unknown libarchive tenth-batch usage case: {case_id}")
PY
