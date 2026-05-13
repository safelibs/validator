#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r16-cpio-newc-insertion-order-preserved
# @title: python-libarchive-c cpio newc preserves entry insertion order across read_memory
# @description: Builds a cpio newc archive in memory via custom_writer with five entries added in a known order, decodes it back via memory_reader, and asserts the iteration order of pathnames matches the original insertion order exactly, exercising cpio's sequential entry layout.
# @timeout: 180
# @tags: usage, archive, cpio, order
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import libarchive

names = ["zeta.txt", "alpha.txt", "middle.txt", "beta.txt", "yankee.txt"]
buf = bytearray()

def cb(chunk):
    buf.extend(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "cpio_newc") as writer:
    for n in names:
        body = ("r16 cpio order " + n).encode()
        writer.add_file_from_memory(n, len(body), body)

raw = bytes(buf)
assert len(raw) > 0

got = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got.append(entry.pathname)

assert got == names, (got, names)
print("cpio-order-ok", got)
PY
