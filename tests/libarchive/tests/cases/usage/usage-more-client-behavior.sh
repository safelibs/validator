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

def read_bytes(payload):
    result = {}
    with libarchive.memory_reader(payload) as archive:
        for entry in archive:
            result[entry.pathname] = b"".join(entry.get_blocks())
    return result

def metadata(path):
    rows = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            rows.append((entry.pathname, entry.size))
            b"".join(entry.get_blocks())
    return rows

if case_id == "usage-python-libarchive-c-tar-binary-payload":
    path = tmpdir / "binary.tar"
    payload = b"\x00\x01\x02alpha\xff"
    write(path, {"binary.bin": payload})
    assert read(path) == {"binary.bin": payload}
    print("tar-binary", len(payload))
elif case_id == "usage-python-libarchive-c-zip-empty-file":
    path = tmpdir / "empty.zip"
    write(path, {"empty.txt": b""}, fmt="zip")
    assert read(path) == {"empty.txt": b""}
    print("zip-empty")
elif case_id == "usage-python-libarchive-c-memory-reader-zip":
    path = tmpdir / "memory.zip"
    expected = {"alpha.txt": b"alpha\n", "beta.txt": b"beta\n"}
    write(path, expected, fmt="zip")
    assert read_bytes(path.read_bytes()) == expected
    print("memory-zip", len(expected))
elif case_id == "usage-python-libarchive-c-memory-reader-tar":
    path = tmpdir / "memory.tar"
    expected = {"first.txt": b"first\n", "second.txt": b"second\n"}
    write(path, expected)
    assert read_bytes(path.read_bytes()) == expected
    print("memory-tar", len(expected))
elif case_id == "usage-python-libarchive-c-cpio-many-files":
    path = tmpdir / "many.cpio"
    expected = {f"file-{i}.txt": f"value-{i}\n".encode() for i in range(6)}
    write(path, expected, fmt="cpio")
    assert read(path) == expected
    print("cpio-many", len(expected))
elif case_id == "usage-python-libarchive-c-pax-long-path":
    path = tmpdir / "long.pax"
    expected = {"alpha/beta/gamma/delta/epsilon/zeta/long-name.txt": b"pax long path\n"}
    write(path, expected, fmt="pax")
    assert read(path) == expected
    print("pax-long")
elif case_id == "usage-python-libarchive-c-tar-binary-nul":
    path = tmpdir / "nul.tar"
    payload = b"prefix\x00middle\x00suffix"
    write(path, {"nul.bin": payload})
    assert read(path)["nul.bin"] == payload
    print("nul-bytes", len(payload))
elif case_id == "usage-python-libarchive-c-zip-repeat-read":
    path = tmpdir / "repeat.zip"
    expected = {"repeat.txt": b"repeat payload\n"}
    write(path, expected, fmt="zip")
    assert read(path) == expected
    assert read(path) == expected
    print("zip-repeat")
elif case_id == "usage-python-libarchive-c-metadata-count":
    path = tmpdir / "metadata.tar"
    expected = {
        "zero.txt": b"",
        "small.txt": b"abc\n",
        "big.txt": b"0123456789abcdef",
    }
    write(path, expected)
    rows = metadata(path)
    assert len(rows) == 3
    assert ("zero.txt", 0) in rows
    assert ("big.txt", 16) in rows
    print("metadata", len(rows))
elif case_id == "usage-python-libarchive-c-zip-binary-payload":
    path = tmpdir / "binary.zip"
    payload = bytes(range(32))
    write(path, {"payload.bin": payload}, fmt="zip")
    assert read(path) == {"payload.bin": payload}
    print("zip-binary", len(payload))
else:
    raise SystemExit(f"unknown libarchive additional usage case: {case_id}")
PY
