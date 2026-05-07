#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r15-fd-writer-then-file-reader
# @title: python-libarchive-c fd_writer cross-path: write via fd, read back via file_reader
# @description: Opens a raw file descriptor with os.open and hands it to libarchive.fd_writer to build a gnutar archive (no path-based writer), then reads the same on-disk file back through libarchive.file_reader (path-based reader). Asserts every (pathname, payload) pair survives the asymmetric fd-write/path-read round trip — distinct from the batch18 fd_writer + fd_reader symmetric case.
# @timeout: 180
# @tags: usage, archive, tar, fd-writer, file-reader
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import os
import sys
from pathlib import Path

import libarchive

tmpdir = Path(sys.argv[1])
arc = tmpdir / "cross.tar"
expected = {
    "alpha.txt": b"r15 cross-path alpha\n",
    "nested/beta.bin": bytes(range(120)),
    "gamma.log": b"r15 cross-path gamma multi-line\nsecond line\nthird\n",
}

write_fd = os.open(str(arc), os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)
try:
    with libarchive.fd_writer(write_fd, "gnutar") as writer:
        for name, body in expected.items():
            writer.add_file_from_memory(name, len(body), body)
finally:
    os.close(write_fd)

assert arc.stat().st_size > 0
assert arc.stat().st_size % 512 == 0, arc.stat().st_size

# Read back through the path-based reader.
got = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())

assert got == expected, (sorted(got.keys()), sorted(expected.keys()))
print("fd-writer-file-reader", sorted(got.keys()))
PY
