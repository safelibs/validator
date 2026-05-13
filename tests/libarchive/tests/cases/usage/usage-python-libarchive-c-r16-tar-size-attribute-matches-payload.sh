#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r16-tar-size-attribute-matches-payload
# @title: python-libarchive-c ustar entry .size equals the original payload length
# @description: Builds a ustar archive in memory containing three entries of distinct known sizes (16, 256, 1024 bytes) via custom_writer, reads them back via memory_reader, and asserts every entry's .size attribute equals the byte length of the body returned by entry.get_blocks(), exercising the size-attribute exposure on the python binding.
# @timeout: 180
# @tags: usage, archive, ustar, size
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import libarchive

expected = {
    "small.bin": bytes(range(16)),
    "medium.bin": bytes(i & 0xFF for i in range(256)),
    "large.bin": bytes(i & 0xFF for i in range(1024)),
}

buf = bytearray()

def cb(chunk):
    buf.extend(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = bytes(buf)
seen = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        body = b"".join(entry.get_blocks())
        assert entry.size == len(body), (entry.pathname, entry.size, len(body))
        assert entry.size == len(expected[entry.pathname]), (entry.pathname, entry.size)
        seen[entry.pathname] = entry.size

assert sorted(seen.keys()) == sorted(expected.keys()), seen
print("size-ok", seen)
PY
