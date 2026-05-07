#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r14-memory-writer-bytesio-tar
# @title: python-libarchive-c custom_writer streams a tar archive into a BytesIO buffer
# @description: Uses libarchive.custom_writer to feed each emitted block into a BytesIO write callback, builds an in-memory ustar archive without touching the filesystem, then re-reads the resulting bytes via libarchive.memory_reader and asserts every entry round-trips.
# @timeout: 60
# @tags: usage, archive, tar, custom-writer, in-memory
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

buf = io.BytesIO()
expected = {
    "alpha.txt": b"custom-writer alpha\n",
    "beta.txt": b"custom-writer beta payload\n",
    "gamma.bin": bytes(range(32)),
}

def sink(data):
    buf.write(data)
    return len(data)

with libarchive.custom_writer(sink, "ustar") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = buf.getvalue()
assert len(raw) > 0 and len(raw) % 512 == 0, len(raw)

seen = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        seen[entry.pathname] = b"".join(entry.get_blocks())

assert seen == expected, sorted(seen)
print("custom-writer", len(seen), len(raw))
PY
