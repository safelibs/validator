#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r15-zip-store-vs-deflate-readback
# @title: python-libarchive-c zip readback parity between store and deflate compression
# @description: Builds two zip archives over the same payload set: one with options="zip:compression=store" and one with the default deflate compression, both via file_writer (format_name="zip", filter_name=None). Reads both back through file_reader and asserts every (pathname, payload) round trips to the same bytes despite the different on-disk compression methods, exercising the libarchive zip-options string for the store path on noble.
# @timeout: 180
# @tags: usage, archive, zip, store, deflate
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
    "alpha.txt": b"r15 zip parity alpha payload\n" * 16,
    "nested/beta.bin": bytes(range(96)),
    "gamma.txt": b"r15 gamma\n",
}

store_path = tmpdir / "store.zip"
deflate_path = tmpdir / "deflate.zip"

# Store: explicit zip:compression=store option.
with libarchive.file_writer(
    str(store_path),
    format_name="zip",
    filter_name=None,
    options="zip:compression=store",
) as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

# Deflate: default zip compression.
with libarchive.file_writer(
    str(deflate_path),
    format_name="zip",
    filter_name=None,
) as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

# Both files share the PK\x03\x04 zip local-file-header magic.
assert store_path.read_bytes()[:4] == b"PK\x03\x04", store_path.read_bytes()[:4]
assert deflate_path.read_bytes()[:4] == b"PK\x03\x04", deflate_path.read_bytes()[:4]

def read(path):
    out = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            out[entry.pathname] = b"".join(entry.get_blocks())
    return out

store_got = read(store_path)
deflate_got = read(deflate_path)

assert store_got == expected, sorted(store_got)
assert deflate_got == expected, sorted(deflate_got)

# The compressed archives should differ on disk but decompress to the same payloads.
assert store_path.read_bytes() != deflate_path.read_bytes(), "store and deflate yielded identical bytes"
print("zip-store-vs-deflate", store_path.stat().st_size, deflate_path.stat().st_size)
PY
