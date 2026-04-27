#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload=${1:?missing python-libarchive-c workload}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$workload" "$tmpdir"
from pathlib import Path
import sys
import libarchive

workload = sys.argv[1]
tmpdir = Path(sys.argv[2])

def read_entries(path):
    entries = []
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            data = b"".join(entry.get_blocks())
            entries.append((entry.pathname, entry.size, data))
    return entries

if workload == "tar-empty-file":
    archive_path = tmpdir / "empty.tar"
    with libarchive.file_writer(str(archive_path), "gnutar") as writer:
        writer.add_file_from_memory("empty.txt", 0, b"")
    entries = read_entries(archive_path)
    assert entries == [("empty.txt", 0, b"")]
    print(entries[0][1])
elif workload == "tar-space-path":
    archive_path = tmpdir / "space.tar"
    with libarchive.file_writer(str(archive_path), "gnutar") as writer:
        writer.add_file_from_memory("dir with space/value.txt", len(b"space\n"), b"space\n")
    data = {name: body for name, _, body in read_entries(archive_path)}
    assert data["dir with space/value.txt"] == b"space\n"
    print(sorted(data))
elif workload == "tar-gzip-memory-reader":
    archive_path = tmpdir / "input.tar.gz"
    with libarchive.file_writer(str(archive_path), "gnutar", "gzip") as writer:
        writer.add_file_from_memory("alpha.txt", len(b"alpha\n"), b"alpha\n")
        writer.add_file_from_memory("beta.txt", len(b"beta\n"), b"beta\n")
    names = []
    with libarchive.memory_reader(archive_path.read_bytes()) as archive:
        for entry in archive:
            names.append(entry.pathname)
            b"".join(entry.get_blocks())
    assert names == ["alpha.txt", "beta.txt"]
    print(",".join(names))
elif workload == "zip-empty-file":
    archive_path = tmpdir / "empty.zip"
    with libarchive.file_writer(str(archive_path), "zip") as writer:
        writer.add_file_from_memory("empty.txt", 0, b"")
    entries = read_entries(archive_path)
    assert entries == [("empty.txt", 0, b"")]
    print(entries[0][1])
elif workload == "zip-many-files-count":
    archive_path = tmpdir / "many.zip"
    with libarchive.file_writer(str(archive_path), "zip") as writer:
        for index in range(5):
            body = f"value-{index}\n".encode()
            writer.add_file_from_memory(f"item-{index}.txt", len(body), body)
    names = [name for name, _, _ in read_entries(archive_path)]
    assert len(names) == 5
    print(len(names))
elif workload == "pax-space-directory":
    archive_path = tmpdir / "space.pax"
    with libarchive.file_writer(str(archive_path), "pax") as writer:
        writer.add_file_from_memory("space dir/", 0, b"", filetype=0o040000, permission=0o755)
        writer.add_file_from_memory("space dir/nested.txt", len(b"nested\n"), b"nested\n")
    names = [name for name, _, _ in read_entries(archive_path)]
    assert "space dir/" in names and "space dir/nested.txt" in names
    print(",".join(names))
elif workload == "cpio-nested-file":
    archive_path = tmpdir / "nested.cpio"
    with libarchive.file_writer(str(archive_path), "cpio") as writer:
        writer.add_file_from_memory("folder/value.txt", len(b"cpio\n"), b"cpio\n")
    data = {name: body for name, _, body in read_entries(archive_path)}
    assert data["folder/value.txt"] == b"cpio\n"
    print(sorted(data))
elif workload == "tar-repeated-read":
    archive_path = tmpdir / "repeat.tar"
    with libarchive.file_writer(str(archive_path), "gnutar") as writer:
        writer.add_file_from_memory("one.txt", len(b"one\n"), b"one\n")
        writer.add_file_from_memory("two.txt", len(b"two\n"), b"two\n")
    first = [name for name, _, _ in read_entries(archive_path)]
    second = [name for name, _, _ in read_entries(archive_path)]
    assert first == second == ["one.txt", "two.txt"]
    print(",".join(first))
elif workload == "zip-memory-reader-names":
    archive_path = tmpdir / "memory.zip"
    with libarchive.file_writer(str(archive_path), "zip") as writer:
        writer.add_file_from_memory("a.txt", len(b"a\n"), b"a\n")
        writer.add_file_from_memory("b.txt", len(b"b\n"), b"b\n")
    names = []
    with libarchive.memory_reader(archive_path.read_bytes()) as archive:
        for entry in archive:
            names.append(entry.pathname)
            b"".join(entry.get_blocks())
    assert names == ["a.txt", "b.txt"]
    print(",".join(names))
elif workload == "tar-long-name":
    archive_path = tmpdir / "long.tar"
    name = "segment/" + ("long-name-" * 7) + "file.txt"
    with libarchive.file_writer(str(archive_path), "gnutar") as writer:
        writer.add_file_from_memory(name, len(b"long\n"), b"long\n")
    data = {entry_name: body for entry_name, _, body in read_entries(archive_path)}
    assert data[name] == b"long\n"
    print(name)
else:
    raise SystemExit(f"unknown python-libarchive-c expanded workload: {workload}")
PYCASE
