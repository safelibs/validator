#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r18-zip-stored-and-deflated-payload-equal
# @title: python-libarchive-c zip readback returns identical payload regardless of options used at write
# @description: Builds two zip archives in memory using libarchive.memory_writer with options "compression=store" and "compression=deflate" containing the same single payload, reads both back via libarchive.memory_reader, and asserts the recovered byte sequences are byte-identical, exercising the lossless invariant across two compression methods.
# @timeout: 60
# @tags: usage, archive, zip, compression, r18
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

payload = b"r18 zip compression-method-invariant payload " + bytes(range(32))

def build(options):
    buf = io.BytesIO()
    def cb(chunk):
        buf.write(bytes(chunk))
        return len(chunk)
    with libarchive.custom_writer(cb, "zip", options=options) as writer:
        writer.add_file_from_memory("only.bin", len(payload), payload)
    return buf.getvalue()

def read_one(blob):
    with libarchive.memory_reader(blob) as archive:
        for entry in archive:
            return b"".join(entry.get_blocks())
    raise AssertionError("no entries")

a = read_one(build("compression=store"))
b = read_one(build("compression=deflate"))
assert a == payload, (len(a), len(payload))
assert b == payload, (len(b), len(payload))
assert a == b
print("zip-compression-invariant-ok", len(a))
PY
