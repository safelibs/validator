#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch21-tar-fd-reader-roundtrip
# @title: python-libarchive-c fd_reader iterates a tar opened by file descriptor
# @description: Writes a single ustar entry with file_writer, then opens the resulting file with os.open and iterates with libarchive.fd_reader, asserting one entry surfaces with the expected pathname, size, and payload. Exercises the fd_reader entrypoint distinct from the file_reader and memory_reader paths used by earlier batches.
# @timeout: 120
# @tags: usage, archive, tar, fd
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
arc = tmpdir / "fd.tar"
payload = b"fd-reader-payload\n"

with libarchive.file_writer(str(arc), "ustar") as writer:
    writer.add_file_from_memory("fd.txt", len(payload), payload)

fd = os.open(str(arc), os.O_RDONLY)
try:
    seen = []
    with libarchive.fd_reader(fd) as archive:
        for entry in archive:
            seen.append((entry.pathname, entry.size, b"".join(entry.get_blocks())))
finally:
    os.close(fd)

assert seen == [("fd.txt", len(payload), payload)], seen
print("fd-reader", seen)
PY
