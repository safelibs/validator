#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r18-tar-pathname-with-dot-prefix
# @title: python-libarchive-c ustar preserves a dot-prefixed relative pathname on readback
# @description: Builds an in-memory ustar archive containing a single entry whose pathname starts with the literal "./" relative prefix and asserts the recovered entry.pathname equals the original dot-prefixed string exactly, exercising the relative-path emission through the ustar writer and reader.
# @timeout: 60
# @tags: usage, archive, ustar, dot-prefix, r18
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

name = "./dot/prefixed.txt"
payload = b"r18 dot-prefix payload\n"
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar") as writer:
    writer.add_file_from_memory(name, len(payload), payload)

raw = buf.getvalue()
got = None
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got = entry.pathname
        b"".join(entry.get_blocks())

assert got == name, (got, name)
print("dot-prefix-ok", got)
PY
