#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch16-cpio-trailer-marker
# @title: python-libarchive-c cpio TRAILER!!! sentinel present
# @description: Writes a cpio archive (libarchive_c default cpio format which is the odc/070707 magic) and asserts the raw archive bytes contain the canonical "TRAILER!!!" sentinel that closes a cpio stream. Re-reads the archive to confirm the entries themselves still parse correctly and the sentinel is treated as an end-of-archive marker rather than a synthetic entry.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch16-cpio-trailer-marker"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "trailer.cpio"
expected = {
    "alpha.txt": b"alpha cpio payload\n",
    "beta.txt": b"beta cpio payload bytes\n",
    "third.txt": b"third cpio payload\n",
}
with libarchive.file_writer(str(archive_path), "cpio") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = archive_path.read_bytes()
# odc cpio magic is "070707" at the start of every header.
assert raw.startswith(b"070707"), raw[:6]
# The trailer record uses the literal "TRAILER!!!" pathname.
assert b"TRAILER!!!" in raw, raw[-128:]

# Reader must not surface the trailer as a user-visible entry.
got = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        assert entry.pathname != "TRAILER!!!", entry.pathname
        got[entry.pathname] = b"".join(entry.get_blocks())

assert got == expected, sorted(got.keys())
print("cpio-trailer", len(raw), len(got))
PY
