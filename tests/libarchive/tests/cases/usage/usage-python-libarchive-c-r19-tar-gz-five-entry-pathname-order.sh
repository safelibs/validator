#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r19-tar-gz-five-entry-pathname-order
# @title: python-libarchive-c ustar+gzip preserves insertion order for five named entries
# @description: Builds an in-memory ustar archive with gzip filter containing five entries named e0.txt through e4.txt added in that order with distinct payloads, reads back via memory_reader, and asserts the recovered pathnames list equals the insertion order, exercising the gzip filter on a small but non-trivial multi-entry archive.
# @timeout: 60
# @tags: usage, archive, ustar, gzip, order, r19
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

names = [f"e{i}.txt" for i in range(5)]
payloads = {n: f"r19 gz entry {i}\n".encode() for i, n in enumerate(names)}

buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar", "gzip") as writer:
    for n in names:
        writer.add_file_from_memory(n, len(payloads[n]), payloads[n])

raw = buf.getvalue()
got = []
got_payloads = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got.append(entry.pathname)
        got_payloads[entry.pathname] = b"".join(entry.get_blocks())

assert got == names, (got, names)
assert got_payloads == payloads, (got_payloads, payloads)
print("tar-gz-five-order-ok", got)
PY
