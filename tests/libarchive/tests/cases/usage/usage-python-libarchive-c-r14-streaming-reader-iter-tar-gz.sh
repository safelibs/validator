#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r14-streaming-reader-iter-tar-gz
# @title: python-libarchive-c stream_reader iterates a tar.gz from a Python file object
# @description: Writes a multi-entry tar.gz with file_writer, opens it as a binary file object, and feeds it to libarchive.stream_reader to iterate the entries, asserting that pathnames and payloads match insertion order through the streaming-reader interface.
# @timeout: 120
# @tags: usage, archive, tar, gzip, stream-reader
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import sys
from pathlib import Path
import libarchive

tmpdir = Path(sys.argv[1])
arc = tmpdir / "stream.tar.gz"
expected = [
    ("alpha.txt", b"alpha stream body\n"),
    ("beta.txt", b"beta stream payload bytes\n"),
    ("gamma.bin", bytes(range(40))),
]

with libarchive.file_writer(str(arc), "ustar", "gzip") as writer:
    for name, body in expected:
        writer.add_file_from_memory(name, len(body), body)

seen = []
with arc.open("rb") as fh:
    with libarchive.stream_reader(fh) as archive:
        for entry in archive:
            seen.append((entry.pathname, b"".join(entry.get_blocks())))

assert seen == expected, [(n, len(b)) for n, b in seen]
print("stream-reader", len(seen))
PY
