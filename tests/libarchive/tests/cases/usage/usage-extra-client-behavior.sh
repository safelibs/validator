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

def metadata(path):
    rows = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            rows.append((entry.pathname, entry.size))
            b"".join(entry.get_blocks())
    return rows

if case_id == "usage-python-libarchive-c-empty-file":
    path = tmpdir / "empty.tar"
    write(path, {"empty.txt": b""})
    data = read(path)
    assert data == {"empty.txt": b""}, data
    print("empty", len(data["empty.txt"]))
elif case_id == "usage-python-libarchive-c-many-files":
    path = tmpdir / "many.tar"
    expected = {f"file-{i}.txt": f"value-{i}\n".encode() for i in range(8)}
    write(path, expected)
    assert read(path) == expected
    print("many", len(expected))
elif case_id == "usage-python-libarchive-c-xz-filter":
    path = tmpdir / "data.tar.xz"
    expected = {"xz.txt": b"xz payload\n"}
    write(path, expected, filt="xz")
    assert read(path) == expected
    print("xz")
elif case_id == "usage-python-libarchive-c-bzip2-filter":
    path = tmpdir / "data.tar.bz2"
    expected = {"bzip2.txt": b"bzip2 payload\n"}
    write(path, expected, filt="bzip2")
    assert read(path) == expected
    print("bzip2")
elif case_id == "usage-python-libarchive-c-zstd-filter":
    path = tmpdir / "data.tar.zst"
    expected = {"zstd.txt": b"zstd payload\n"}
    write(path, expected, filt="zstd")
    assert read(path) == expected
    print("zstd")
elif case_id == "usage-python-libarchive-c-pax-format":
    path = tmpdir / "data.pax"
    expected = {"dir/pax.txt": b"pax payload\n"}
    write(path, expected, fmt="pax")
    assert read(path) == expected
    print("pax")
elif case_id == "usage-python-libarchive-c-cpio-newc":
    path = tmpdir / "data.cpio"
    expected = {"newc.txt": b"newc payload\n"}
    write(path, expected, fmt="cpio")
    assert read(path) == expected
    print("newc")
elif case_id == "usage-python-libarchive-c-large-entry":
    path = tmpdir / "large.tar"
    payload = (b"0123456789abcdef" * 4096)
    write(path, {"large.bin": payload})
    data = read(path)
    assert data["large.bin"] == payload
    print("large", len(payload))
elif case_id == "usage-python-libarchive-c-spaced-name":
    path = tmpdir / "spaced.tar"
    expected = {"dir/space name.txt": b"space payload\n"}
    write(path, expected)
    assert read(path) == expected
    print("space name")
elif case_id == "usage-python-libarchive-c-zip-to-tar":
    zip_path = tmpdir / "input.zip"
    tar_path = tmpdir / "output.tar"
    expected = {"alpha.txt": b"alpha\n", "beta.txt": b"beta\n"}
    write(zip_path, expected, fmt="zip")
    with libarchive.file_reader(str(zip_path)) as entries, libarchive.file_writer(str(tar_path), "gnutar") as writer:
        writer.add_entries(entries)
    assert read(tar_path) == expected
    print("zip-to-tar")
elif case_id == "usage-python-libarchive-c-lz4-filter":
    path = tmpdir / "data.tar.lz4"
    expected = {"lz4.txt": b"lz4 payload\n"}
    write(path, expected, filt="lz4")
    assert read(path) == expected
    print("lz4")
elif case_id == "usage-python-libarchive-c-lzop-filter":
    path = tmpdir / "data.tar.lzo"
    expected = {"lzop.txt": b"lzop payload\n"}
    write(path, expected, filt="lzop")
    assert read(path) == expected
    print("lzop")
elif case_id == "usage-python-libarchive-c-lzip-filter":
    path = tmpdir / "data.tar.lz"
    expected = {"lzip.txt": b"lzip payload\n"}
    write(path, expected, filt="lzip")
    assert read(path) == expected
    print("lzip")
elif case_id == "usage-python-libarchive-c-lzma-filter":
    path = tmpdir / "data.tar.lzma"
    expected = {"lzma.txt": b"lzma payload\n"}
    write(path, expected, filt="lzma")
    assert read(path) == expected
    print("lzma")
elif case_id == "usage-python-libarchive-c-ustar-format":
    path = tmpdir / "data.ustar"
    expected = {"ustar.txt": b"ustar payload\n"}
    write(path, expected, fmt="ustar")
    assert read(path) == expected
    print("ustar")
elif case_id == "usage-python-libarchive-c-tar-to-zip":
    tar_path = tmpdir / "input.tar"
    zip_path = tmpdir / "output.zip"
    expected = {"alpha.txt": b"alpha\n", "beta.txt": b"beta\n"}
    write(tar_path, expected)
    with libarchive.file_reader(str(tar_path)) as entries, libarchive.file_writer(str(zip_path), "zip") as writer:
        writer.add_entries(entries)
    assert read(zip_path) == expected
    print("tar-to-zip")
elif case_id == "usage-python-libarchive-c-long-path":
    path = tmpdir / "long.tar"
    expected = {"alpha/beta/gamma/delta/epsilon.txt": b"long path payload\n"}
    write(path, expected)
    assert read(path) == expected
    print("long-path")
elif case_id == "usage-python-libarchive-c-size-metadata":
    path = tmpdir / "sizes.tar"
    expected = {
        "zero.txt": b"",
        "short.txt": b"abc\n",
        "long.txt": b"0123456789abcdef",
    }
    write(path, expected)
    rows = metadata(path)
    assert ("zero.txt", 0) in rows
    assert ("short.txt", 4) in rows
    assert ("long.txt", 16) in rows
    print("sizes", len(rows))
elif case_id == "usage-python-libarchive-c-repeat-read":
    path = tmpdir / "repeat.tar"
    expected = {"repeat.txt": b"repeat payload\n"}
    write(path, expected)
    assert read(path) == expected
    assert read(path) == expected
    print("repeat")
elif case_id == "usage-python-libarchive-c-zip-many-files":
    path = tmpdir / "many.zip"
    expected = {f"file-{i}.txt": f"value-{i}\n".encode() for i in range(12)}
    write(path, expected, fmt="zip")
    assert read(path) == expected
    print("zip-many", len(expected))
else:
    raise SystemExit(f"unknown libarchive extra usage case: {case_id}")
PY
