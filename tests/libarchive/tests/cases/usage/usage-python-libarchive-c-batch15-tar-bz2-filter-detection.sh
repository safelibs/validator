#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch15-tar-bz2-filter-detection
# @title: python-libarchive-c tar.bz2 write+read with filter detection
# @description: Writes a gnutar archive through the bzip2 filter via python-libarchive-c, then reads it back without specifying the filter so libarchive's bidder must auto-detect bzip2 from the magic bytes. Verifies the file header is BZh, the entry payload roundtrips, and the on-disk file is materially smaller than a plain tar of the same payload (so the filter actually compressed).
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch15-tar-bz2-filter-detection"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

# Make the payload compressible enough that bzip2 must shrink it; any
# repetitive byte pattern is fine here.
payload = (b"libarchive bzip2 filter detection payload bytes\n" * 256)
entries = {"alpha.txt": payload, "beta.txt": payload[::-1]}

bz_path = tmpdir / "out.tar.bz2"
with libarchive.file_writer(str(bz_path), "gnutar", "bzip2") as writer:
    for name, data in entries.items():
        writer.add_file_from_memory(name, len(data), data)

# bzip2 magic: 'BZh'
header = bz_path.read_bytes()[:3]
assert header == b"BZh", header

# Reader call site deliberately omits format_name/filter_name so libarchive
# must auto-detect both from the stream prefix.
got = {}
with libarchive.file_reader(str(bz_path)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == entries, sorted(got.keys())

# Sanity: a plain (uncompressed) gnutar of the same payload should be
# meaningfully larger than the bzip2-filtered archive.
plain_path = tmpdir / "out.tar"
with libarchive.file_writer(str(plain_path), "gnutar") as writer:
    for name, data in entries.items():
        writer.add_file_from_memory(name, len(data), data)

plain_size = plain_path.stat().st_size
bz_size = bz_path.stat().st_size
assert bz_size < plain_size, (bz_size, plain_size)
print("tar-bz2-detection", bz_size, plain_size)
PY
