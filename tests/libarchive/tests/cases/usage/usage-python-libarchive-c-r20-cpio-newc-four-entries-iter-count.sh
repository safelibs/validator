#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r20-cpio-newc-four-entries-iter-count
# @title: python-libarchive-c cpio "newc" four-entry archive yields exactly four iter entries
# @description: Builds an in-memory cpio archive (format "newc") via custom_writer with four named entries with small payloads and asserts that iterating via memory_reader yields exactly 4 entries, exercising the cpio iteration-count invariant for a four-entry archive distinct from the existing three-entry (r19) and twelve-entry (batch20) cases.
# @timeout: 60
# @tags: usage, archive, cpio, iter-count, r20
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

names = ["one.txt", "two.txt", "three.txt", "four.txt"]
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "cpio_newc") as writer:
    for n in names:
        payload = ("r20-" + n).encode()
        writer.add_file_from_memory(n, len(payload), payload)

raw = buf.getvalue()
count = 0
got = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        count += 1
        got.append(entry.pathname)

assert count == 4, (count, got)
assert got == names, got
print("cpio-newc-four-ok", got)
PY
