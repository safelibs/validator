#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch18-fd-writer-roundtrip
# @title: python-libarchive-c fd_writer + fd_reader roundtrip
# @description: Opens a raw OS file descriptor with os.open and hands it to libarchive.fd_writer to build a gnutar archive, exercising the file-descriptor entry point distinct from the path-based file_writer. Reopens the same path through os.open and reads the entries back via libarchive.fd_reader, asserting that every (pathname, payload) pair round trips through the fd-based read/write pair.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch18-fd-writer-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import os
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "fd.tar"
expected = {
    "alpha.txt": b"alpha fd writer payload\n",
    "nested/beta.bin": bytes(range(64)),
    "gamma.log": b"gamma multi-line\nsecond line\n",
}

# Write side: open the file with os.open and pass the raw fd into fd_writer.
write_fd = os.open(str(archive_path), os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)
try:
    with libarchive.fd_writer(write_fd, "gnutar") as writer:
        for name, body in expected.items():
            writer.add_file_from_memory(name, len(body), body)
finally:
    os.close(write_fd)

# tar streams are a non-empty multiple of 512 bytes.
assert archive_path.stat().st_size > 0
assert archive_path.stat().st_size % 512 == 0, archive_path.stat().st_size

# Read side: open the same path with os.open and stream through fd_reader.
read_fd = os.open(str(archive_path), os.O_RDONLY)
got = {}
try:
    with libarchive.fd_reader(read_fd) as archive:
        for entry in archive:
            got[entry.pathname] = b"".join(entry.get_blocks())
finally:
    os.close(read_fd)

assert got == expected, (sorted(got.keys()), sorted(expected.keys()))
print("fd-roundtrip", archive_path.stat().st_size, sorted(got.keys()))
PY
