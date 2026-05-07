#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r15-extract-memory-tarball
# @title: python-libarchive-c libarchive.extract_memory writes archive contents to disk
# @description: Builds a small ustar archive in memory via memory_writer (libarchive.custom_writer with a bytes-sink callback), then changes into a fresh directory and calls libarchive.extract_memory(buf) — the binding's helper that decodes an archive image directly from a bytes blob to the current working directory. Asserts every original payload now lives at the expected on-disk path with matching contents, exercising the extract_memory entrypoint distinct from extract_file used by other batches.
# @timeout: 180
# @tags: usage, archive, extract, memory
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
expected = {
    "alpha.txt": b"r15 extract_memory alpha payload\n",
    "nested/beta.txt": b"r15 extract_memory nested beta\n" * 4,
    "gamma.bin": bytes(range(72)),
}

# Build archive bytes purely in memory via custom_writer.
buf = bytearray()

def cb(chunk):
    buf.extend(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = bytes(buf)
assert len(raw) > 0 and len(raw) % 512 == 0, len(raw)

# Extract directly from the in-memory blob into a fresh cwd.
out_dir = tmpdir / "out"
out_dir.mkdir()
prev = Path.cwd()
os.chdir(out_dir)
try:
    libarchive.extract_memory(raw)
finally:
    os.chdir(prev)

for name, body in expected.items():
    target = out_dir / name
    assert target.is_file(), (name, target)
    got = target.read_bytes()
    assert got == body, (name, len(got), len(body))
print("extract-memory", sorted(expected.keys()))
PY
