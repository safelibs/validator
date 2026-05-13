#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r16-pax-many-small-entries
# @title: python-libarchive-c pax memory archive iterates 200 entries in insertion order
# @description: Builds a pax archive in memory via custom_writer containing 200 entries named entry-000.txt through entry-199.txt with distinct payloads, decodes it via memory_reader, and asserts the iteration order equals the original insertion order and that every payload matches exactly, exercising pax with many short entries.
# @timeout: 180
# @tags: usage, archive, pax, scale
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import libarchive

N = 200
names = [f"entry-{i:03d}.txt" for i in range(N)]
expected = {n: f"r16 pax {n}\n".encode() for n in names}

buf = bytearray()

def cb(chunk):
    buf.extend(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "pax") as writer:
    for n in names:
        body = expected[n]
        writer.add_file_from_memory(n, len(body), body)

raw = bytes(buf)
assert len(raw) > 0

got_order = []
got_payloads = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got_order.append(entry.pathname)
        got_payloads[entry.pathname] = b"".join(entry.get_blocks())

assert got_order == names, (got_order[:5], names[:5])
assert got_payloads == expected, sorted(got_payloads)[:5]
print("pax-many-ok", len(got_order))
PY
