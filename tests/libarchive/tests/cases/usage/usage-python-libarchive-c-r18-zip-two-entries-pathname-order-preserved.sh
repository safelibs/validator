#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r18-zip-two-entries-pathname-order-preserved
# @title: python-libarchive-c zip two-entry archive preserves insertion order on iteration
# @description: Builds an in-memory zip archive via custom_writer with two named entries inserted in a deliberate non-alphabetical order, reads back via memory_reader, and asserts the iteration pathname sequence equals the original write order, exercising the zip writer order-preservation guarantee on a two-entry archive.
# @timeout: 60
# @tags: usage, archive, zip, order, r18
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

order = ["zulu.txt", "alpha.txt"]
data = {n: ("r18-zip-" + n + "-payload\n").encode() for n in order}
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "zip") as writer:
    for n in order:
        writer.add_file_from_memory(n, len(data[n]), data[n])

raw = buf.getvalue()
got_order = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got_order.append(entry.pathname)
        b"".join(entry.get_blocks())

assert got_order == order, (got_order, order)
print("zip-order-ok", got_order)
PY
