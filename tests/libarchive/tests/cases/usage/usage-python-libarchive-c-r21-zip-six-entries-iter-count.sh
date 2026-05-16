#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r21-zip-six-entries-iter-count
# @title: python-libarchive-c zip six-entry archive yields exactly six iter entries
# @description: Builds an in-memory zip archive via custom_writer with six named entries with small distinct payloads and asserts memory_reader iteration yields exactly 6 entries with the original pathnames in insertion order, exercising the zip iter-count invariant at six entries distinct from prior two/twenty (r21 batches) entry zip iter-count tests.
# @timeout: 60
# @tags: usage, archive, zip, iter-count, r21
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

names = ["e1.txt", "e2.txt", "e3.txt", "e4.txt", "e5.txt", "e6.txt"]
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "zip") as writer:
    for n in names:
        payload = ("r21-zip-" + n).encode()
        writer.add_file_from_memory(n, len(payload), payload)

raw = buf.getvalue()
got = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got.append(entry.pathname)

assert got == names, got
print("zip-six-ok", got)
PY
