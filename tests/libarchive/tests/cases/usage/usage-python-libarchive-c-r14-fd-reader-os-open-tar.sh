#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r14-fd-reader-os-open-tar
# @title: python-libarchive-c fd_reader iterates a tar archive opened via os.open
# @description: Writes a tar archive on disk, opens it through os.open(O_RDONLY), and passes the integer file descriptor to libarchive.fd_reader, asserting iteration produces every inserted entry with payload intact.
# @timeout: 60
# @tags: usage, archive, tar, fd-reader
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
expected = {
    "fd-alpha.txt": b"fd alpha body\n",
    "fd-beta.txt": b"fd beta body bytes\n",
}

with libarchive.file_writer(str(arc), "ustar") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

fd = os.open(str(arc), os.O_RDONLY)
try:
    seen = {}
    with libarchive.fd_reader(fd) as archive:
        for entry in archive:
            seen[entry.pathname] = b"".join(entry.get_blocks())
finally:
    os.close(fd)

assert seen == expected, sorted(seen)
print("fd-reader", len(seen))
PY
