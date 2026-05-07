#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r15-tar-zstd-stream-reader
# @title: python-libarchive-c stream_reader iterates a tar.zst from a binary file object
# @description: Writes a multi-entry tar.zst via file_writer with the zstd filter, opens it as a binary file object and feeds it to libarchive.stream_reader (distinct from the r14 stream_reader-tar-gz case). Asserts pathnames and payloads round trip in insertion order through the streaming-reader interface against a zstd-compressed input rather than gzip.
# @timeout: 120
# @tags: usage, archive, tar, zstd, stream-reader
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
arc = tmpdir / "stream.tar.zst"
expected = [
    ("alpha.txt", b"r15 zstd stream alpha\n"),
    ("nested/beta.bin", bytes(range(48))),
    ("gamma.txt", b"r15 zstd stream gamma payload\n" * 8),
]

with libarchive.file_writer(str(arc), "ustar", "zstd") as writer:
    for name, body in expected:
        writer.add_file_from_memory(name, len(body), body)

# zstd magic 28 b5 2f fd
magic = arc.read_bytes()[:4]
assert magic == b"\x28\xb5\x2f\xfd", magic.hex()

seen = []
with arc.open("rb") as fh:
    with libarchive.stream_reader(fh) as archive:
        for entry in archive:
            seen.append((entry.pathname, b"".join(entry.get_blocks())))

assert seen == expected, [(n, len(b)) for n, b in seen]
print("zstd-stream-reader", len(seen))
PY
