#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch19-zip-store-and-deflate-equal-payload
# @title: python-libarchive-c zip store vs deflate yield identical payload bytes
# @description: Writes the same payload as a zip with compression=store and again with deflate, then verifies file_reader returns byte-identical entry payloads from both archives.
# @timeout: 120
# @tags: usage, archive, zip
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
payload = b"abcde" * 1000

def write(path, opt):
    with libarchive.file_writer(str(path), "zip", options=opt) as writer:
        writer.add_file_from_memory("blob.bin", len(payload), payload)

def read(path):
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            return b"".join(entry.get_blocks())

p_store = tmpdir / "store.zip"
p_deflate = tmpdir / "deflate.zip"
write(p_store, "zip:compression=store")
write(p_deflate, "zip:compression=deflate")

s_size = p_store.stat().st_size
d_size = p_deflate.stat().st_size
print("store_size", s_size, "deflate_size", d_size)

s_payload = read(p_store)
d_payload = read(p_deflate)
assert s_payload == payload
assert d_payload == payload
# Highly compressible payload: deflate must be strictly smaller than store.
assert d_size < s_size, (d_size, s_size)
PY
