#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch18-mtree-gzip-filter
# @title: python-libarchive-c mtree with gzip filter
# @description: Writes an mtree manifest with the gzip filter chain enabled (libarchive.file_writer(..., "mtree", filter_name="gzip")), so the resulting file is a gzip-compressed mtree spec. Asserts the on-disk bytes start with the gzip 0x1f 0x8b magic, then reads the manifest back through libarchive.file_reader and verifies every entry name written is yielded after stripping the leading "./" mtree convention prefix.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch18-mtree-gzip-filter"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "out.mtree.gz"
expected = {
    "alpha.txt": b"alpha mtree gzip body\n",
    "beta.bin": b"\x00\x01\x02\x03beta-binary",
    "subdir/leaf.log": b"leaf log line one\nline two\n",
}

with libarchive.file_writer(
    str(archive_path), "mtree", filter_name="gzip"
) as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = archive_path.read_bytes()
# gzip magic per RFC 1952.
assert raw[:2] == b"\x1f\x8b", raw[:8]

names_seen = []
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        names_seen.append(entry.pathname)
        # mtree carries metadata only; payload may or may not be available.
        b"".join(entry.get_blocks())

# libarchive's mtree reader emits paths with a leading "./" prefix.
normalised = sorted(
    name[2:] if name.startswith("./") else name for name in names_seen
)
assert normalised == sorted(expected.keys()), (normalised, sorted(expected))
print("mtree-gzip", len(raw), normalised)
PY
