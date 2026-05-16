#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r21-cpio-odc-three-entries-iter-count
# @title: python-libarchive-c cpio "odc" three-entry archive yields exactly three iter entries
# @description: Builds an in-memory cpio archive using the "odc" portable ASCII format via custom_writer with three named entries and asserts memory_reader iteration yields exactly 3 entries with the same pathnames in the original order, exercising the cpio-odc iteration distinct from the existing cpio_newc iter-count tests at three/four/twelve entries.
# @timeout: 60
# @tags: usage, archive, cpio, odc, iter-count, r21
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

names = ["alpha.txt", "beta.txt", "gamma.txt"]
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "cpio") as writer:
    for n in names:
        payload = ("r21-" + n).encode()
        writer.add_file_from_memory(n, len(payload), payload)

raw = buf.getvalue()
got = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got.append(entry.pathname)

assert got == names, got
print("cpio-odc-three-ok", got)
PY
