#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r21-7zip-two-entries-iter-count
# @title: python-libarchive-c 7zip two-entry archive yields exactly two iter entries
# @description: Builds an in-memory 7zip archive via custom_writer with two named entries with small distinct payloads and asserts memory_reader iteration yields exactly 2 entries with the original pathnames in insertion order, exercising the 7zip iter-count invariant at two entries distinct from the existing one (r19 empty-payload) and three (r13) entry 7zip cases.
# @timeout: 120
# @tags: usage, archive, 7zip, iter-count, r21
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

names = ["sevenz1.bin", "sevenz2.bin"]
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "7zip") as writer:
    for n in names:
        payload = ("r21-7zip-" + n).encode()
        writer.add_file_from_memory(n, len(payload), payload)

raw = buf.getvalue()
got = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got.append(entry.pathname)

assert got == names, got
print("7zip-two-ok", got)
PY
