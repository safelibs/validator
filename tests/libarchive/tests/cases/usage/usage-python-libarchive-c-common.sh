#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload=${1:?missing python-libarchive-c workload}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$workload" "$tmpdir"
from pathlib import Path
import sys
import libarchive

workload = sys.argv[1]
tmpdir = Path(sys.argv[2])

def write_archive(path, *, gzip=False):
    with libarchive.file_writer(str(path), "gnutar", "gzip" if gzip else None) as writer:
        writer.add_file_from_memory("alpha.txt", len(b"alpha\n"), b"alpha\n")
        writer.add_file_from_memory("beta.txt", len(b"beta\n"), b"beta\n")

def read_entries(path):
    entries = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            data = b"".join(entry.get_blocks())
            entries.append((entry.pathname, entry.size, data))
    return entries

archive_path = tmpdir / "input.tar"

if workload == "tar-list":
    write_archive(archive_path)
    names = [name for name, _, _ in read_entries(archive_path)]
    print("entries", ",".join(names))
    assert "alpha.txt" in names and "beta.txt" in names
elif workload == "tar-extract":
    write_archive(archive_path)
    out = tmpdir / "out"
    out.mkdir()
    for name, _, data in read_entries(archive_path):
        (out / name).write_bytes(data)
    print((out / "alpha.txt").read_text().strip())
    assert (out / "beta.txt").read_text() == "beta\n"
elif workload == "metadata-read":
    write_archive(archive_path)
    metadata = [(name, size) for name, size, _ in read_entries(archive_path)]
    print(metadata)
    assert ("alpha.txt", 6) in metadata
elif workload == "stream-read":
    write_archive(archive_path)
    payload = archive_path.read_bytes()
    names = []
    with libarchive.memory_reader(payload) as archive:
        for entry in archive:
            names.append(entry.pathname)
            b"".join(entry.get_blocks())
    print("stream", ",".join(names))
    assert names == ["alpha.txt", "beta.txt"]
elif workload == "file-roundtrip":
    roundtrip = tmpdir / "roundtrip.tar"
    with libarchive.file_writer(str(roundtrip), "gnutar") as writer:
        writer.add_file_from_memory("one.txt", len(b"one\n"), b"one\n")
        writer.add_file_from_memory("two.txt", len(b"two\n"), b"two\n")
    data = {name: body.decode() for name, _, body in read_entries(roundtrip)}
    print(data)
    assert data["one.txt"] == "one\n" and data["two.txt"] == "two\n"
elif workload == "directory-entry":
    directory_archive = tmpdir / "directory.tar"
    with libarchive.file_writer(str(directory_archive), "gnutar") as writer:
        writer.add_file_from_memory("tree/", 0, b"", filetype=0o040000, permission=0o755)
        writer.add_file_from_memory("tree/nested.txt", len(b"nested\n"), b"nested\n")
    names = [name for name, _, _ in read_entries(directory_archive)]
    print("directory", ",".join(names))
    assert "tree/" in names and "tree/nested.txt" in names
elif workload == "copy-mode":
    write_archive(archive_path)
    copy_path = tmpdir / "copy.tar"
    with libarchive.file_reader(str(archive_path)) as entries, libarchive.file_writer(str(copy_path), "gnutar") as writer:
        writer.add_entries(entries)
    copied = {name: body.decode() for name, _, body in read_entries(copy_path)}
    print(copied)
    assert copied["alpha.txt"] == "alpha\n"
elif workload == "gzip-filter":
    gzip_archive = tmpdir / "input.tar.gz"
    write_archive(gzip_archive, gzip=True)
    names = [name for name, _, _ in read_entries(gzip_archive)]
    print("gzip", ",".join(names))
    assert names == ["alpha.txt", "beta.txt"]
elif workload == "zip-roundtrip":
    zip_archive = tmpdir / "roundtrip.zip"
    expected = {
        "zip-alpha.txt": b"zip alpha\n",
        "zip-beta.txt": b"zip beta\n",
    }
    with libarchive.file_writer(str(zip_archive), "zip") as writer:
        for name, body in expected.items():
            writer.add_file_from_memory(name, len(body), body)
    data = {name: body for name, _, body in read_entries(zip_archive)}
    print("zip-roundtrip", ",".join(sorted(data)))
    assert data == expected
elif workload == "nested-paths":
    nested_archive = tmpdir / "nested.tar"
    expected = {
        "dir/sub.txt": b"sub\n",
        "dir/space name.txt": b"space name\n",
    }
    with libarchive.file_writer(str(nested_archive), "gnutar") as writer:
        for name, body in expected.items():
            writer.add_file_from_memory(name, len(body), body)
    data = {name: body for name, _, body in read_entries(nested_archive)}
    print("nested-paths", ",".join(sorted(data)))
    assert data == expected
else:
    raise SystemExit(f"unknown python-libarchive-c workload: {workload}")
PY
