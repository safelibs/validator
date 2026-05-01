#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch17-tar-zstd-explicit-level19
# @title: python-libarchive-c tar.zst with zstd compression-level=19
# @description: Builds a tar.zst archive by passing options="zstd:compression-level=19" to libarchive.file_writer with the zstd filter, then verifies the resulting bytes start with the zstd frame magic 0x28B52FFD and round trip through libarchive.file_reader. Compares the on-disk size against an equivalent zstd:compression-level=1 archive and asserts the level-19 output is no larger, exercising the explicit zstd-level option negotiation through libarchive's filter option parser.
# @timeout: 240
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch17-tar-zstd-explicit-level19"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

# Highly repetitive content so both levels compress aggressively but level 19
# typically reaches a smaller (or equal) frame than level 1.
payload = (b"zstd compression level test payload chunk\n" * 8192)
expected = {
    "alpha.txt": payload,
    "beta.txt": payload[: len(payload) // 2],
}

high_path = tmpdir / "high.tar.zst"
low_path = tmpdir / "low.tar.zst"

with libarchive.file_writer(
    str(high_path), "gnutar", filter_name="zstd",
    options="zstd:compression-level=19",
) as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

with libarchive.file_writer(
    str(low_path), "gnutar", filter_name="zstd",
    options="zstd:compression-level=1",
) as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

high_raw = high_path.read_bytes()
low_raw = low_path.read_bytes()
# zstd frame magic per RFC 8478.
assert high_raw[:4] == b"\x28\xb5\x2f\xfd", high_raw[:4]
assert low_raw[:4] == b"\x28\xb5\x2f\xfd", low_raw[:4]
# Higher level should produce a no-larger archive on this very repetitive blob.
assert len(high_raw) <= len(low_raw), (len(high_raw), len(low_raw))

got = {}
with libarchive.file_reader(str(high_path)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == expected, sorted(got.keys())
print("zstd-level19", len(high_raw), len(low_raw))
PY
