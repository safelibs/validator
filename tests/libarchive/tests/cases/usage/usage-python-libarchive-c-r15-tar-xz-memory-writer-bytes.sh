#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r15-tar-xz-memory-writer-bytes
# @title: python-libarchive-c custom_writer captures a tar.xz stream into a bytes buffer
# @description: Builds a tar.xz archive entirely in memory by handing libarchive.custom_writer a bytes-appending callback with format_name="ustar" and filter_name="xz". Verifies the captured blob carries the .xz magic bytes (fd 37 7a 58 5a 00) and decodes losslessly through libarchive.memory_reader, recovering every entry's pathname and payload — distinct from the batch17 plain-gnutar memory-writer case by adding the xz filter on top.
# @timeout: 180
# @tags: usage, archive, tar, xz, memory-writer
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
expected = {
    "alpha.txt": b"r15 mem-writer xz alpha\n" * 8,
    "nested/beta.bin": bytes(range(64)),
    "gamma.log": b"r15 mem-writer xz gamma payload\n",
}

captured = bytearray()

def cb(chunk):
    captured.extend(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar", "xz") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = bytes(captured)
assert len(raw) > 0, len(raw)
# .xz magic: FD 37 7A 58 5A 00
assert raw[:6] == b"\xfd\x37\x7a\x58\x5a\x00", raw[:6].hex()

got = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == expected, sorted(got.keys())
print("tar-xz-memory-writer", len(raw), len(got))
PY
