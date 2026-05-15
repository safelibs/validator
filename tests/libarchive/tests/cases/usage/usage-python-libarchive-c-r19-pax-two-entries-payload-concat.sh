#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r19-pax-two-entries-payload-concat
# @title: python-libarchive-c pax two-entry archive recovers each payload independently and concatenates correctly
# @description: Builds an in-memory pax archive via custom_writer with two named entries containing distinct payloads, reads back via memory_reader, and asserts that the concatenation of the two recovered payloads (in iteration order) equals the concatenation of the source payloads in the same order, exercising the pax format multi-entry payload preservation invariant.
# @timeout: 60
# @tags: usage, archive, pax, multi-entry, r19
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

entries = [
    ("first.bin", b"r19 pax first " + bytes(range(32))),
    ("second.bin", b"r19 pax second " + bytes(range(32, 80))),
]
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "pax") as writer:
    for n, p in entries:
        writer.add_file_from_memory(n, len(p), p)

raw = buf.getvalue()
got_seq = []
got_concat = b""
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        body = b"".join(entry.get_blocks())
        got_seq.append((entry.pathname, body))
        got_concat += body

expected_concat = b"".join(p for _, p in entries)
assert got_concat == expected_concat, (len(got_concat), len(expected_concat))
assert [n for n, _ in got_seq] == [n for n, _ in entries], got_seq
print("pax-concat-ok", len(got_concat))
PY
