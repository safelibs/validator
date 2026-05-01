#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch18-tar-bzip2-level9
# @title: python-libarchive-c tar.bz2 with bzip2 compression-level=9
# @description: Builds a tar.bz2 archive by passing options="bzip2:compression-level=9" to libarchive.file_writer with the bzip2 filter, asserts the resulting bytes start with the bzip2 "BZh9" header (the "9" is the level digit baked into the bzip2 stream header), and rebuilds an equivalent archive at compression-level=1 to confirm the level-9 output is no larger on highly repetitive payload. Reads the level-9 archive back via libarchive.file_reader and verifies the entries round trip byte-for-byte.
# @timeout: 240
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch18-tar-bzip2-level9"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

# Highly compressible repeating payload so level=9 reaches at least
# the same compression ratio as level=1 on this input.
payload = b"bzip2 level test repeating chunk bytes\n" * 4096
expected = {
    "alpha.txt": payload,
    "beta.txt": payload[: len(payload) // 2],
}

high_path = tmpdir / "high.tar.bz2"
low_path = tmpdir / "low.tar.bz2"

with libarchive.file_writer(
    str(high_path), "gnutar", filter_name="bzip2",
    options="bzip2:compression-level=9",
) as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

with libarchive.file_writer(
    str(low_path), "gnutar", filter_name="bzip2",
    options="bzip2:compression-level=1",
) as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

high_raw = high_path.read_bytes()
low_raw = low_path.read_bytes()
# bzip2 stream header carries the block-size digit (1..9) in the 4th byte.
assert high_raw[:4] == b"BZh9", high_raw[:4]
assert low_raw[:4] == b"BZh1", low_raw[:4]
assert len(high_raw) <= len(low_raw), (len(high_raw), len(low_raw))

got = {}
with libarchive.file_reader(str(high_path)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == expected, sorted(got.keys())
print("bzip2-level9", len(high_raw), len(low_raw))
PY
