#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-tar-xz-memory-reader
# @title: python-libarchive-c tar xz memory reader
# @description: Reads an xz-compressed gnutar archive from memory through python-libarchive-c and verifies the member order.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-tar-xz-memory-reader"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "input.tar.xz"
with libarchive.file_writer(str(archive_path), "gnutar", "xz") as writer:
    writer.add_file_from_memory("alpha.txt", len(b"alpha\n"), b"alpha\n")
    writer.add_file_from_memory("beta.txt", len(b"beta\n"), b"beta\n")
    writer.add_file_from_memory("gamma.txt", len(b"gamma\n"), b"gamma\n")

# Confirm xz container magic on disk before doing the memory read.
head = archive_path.read_bytes()[:6]
assert head == b"\xfd7zXZ\x00", f"unexpected xz header bytes: {head!r}"

names = []
sizes = []
payload = archive_path.read_bytes()
with libarchive.memory_reader(payload) as archive:
    for entry in archive:
        names.append(entry.pathname)
        body = b"".join(entry.get_blocks())
        sizes.append(len(body))

assert names == ["alpha.txt", "beta.txt", "gamma.txt"], names
assert sizes == [6, 5, 6], sizes
print("tar-xz-memory", ",".join(names))
PY
