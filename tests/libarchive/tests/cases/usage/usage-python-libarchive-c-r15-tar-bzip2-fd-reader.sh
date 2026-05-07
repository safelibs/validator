#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r15-tar-bzip2-fd-reader
# @title: python-libarchive-c fd_reader iterates a tar.bz2 opened by file descriptor
# @description: Writes a tar.bz2 via file_writer with the bzip2 filter, opens the resulting file with os.open and iterates with libarchive.fd_reader. Asserts every entry surfaces with the expected pathname, size, and payload — exercising the fd_reader path against a bzip2-compressed tar (distinct from the batch21 plain-tar fd-reader case).
# @timeout: 120
# @tags: usage, archive, tar, bzip2, fd
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
arc = tmpdir / "fd.tar.bz2"
expected = {
    "alpha.txt": b"r15 fd-reader bzip2 alpha\n",
    "beta.txt": b"r15 fd-reader bzip2 beta payload\n" * 4,
    "gamma.bin": bytes(range(64)),
}

with libarchive.file_writer(str(arc), "ustar", "bzip2") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

# bzip2 magic "BZh"
assert arc.read_bytes()[:3] == b"BZh", arc.read_bytes()[:3]

fd = os.open(str(arc), os.O_RDONLY)
try:
    seen = {}
    with libarchive.fd_reader(fd) as archive:
        for entry in archive:
            seen[entry.pathname] = (entry.size, b"".join(entry.get_blocks()))
finally:
    os.close(fd)

for name, body in expected.items():
    assert name in seen, (name, sorted(seen))
    size, data = seen[name]
    assert size == len(body), (name, size, len(body))
    assert data == body, (name, len(data), len(body))
print("bzip2-fd-reader", sorted(seen.keys()))
PY
