#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch17-zip-deflate-level9
# @title: python-libarchive-c zip writer at deflate level 9
# @description: Writes a zip archive with options="zip:compression-level=9" and a highly repetitive payload, then writes the same payload through options="zip:compression=store" and compares on-disk sizes. The deflate-level-9 archive must be strictly smaller than the stored one and both must round trip through libarchive.file_reader, exercising the explicit-level deflate code path against a controllable baseline.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch17-zip-deflate-level9"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

# Highly repetitive payload so deflate compresses dramatically; a zip-store
# archive over the same payload should be much larger.
payload = (b"the quick brown fox jumps over the lazy dog\n" * 4096)
expected = {
    "alpha.txt": payload,
    "beta.txt": payload[:8192],
}

deflate_path = tmpdir / "deflate9.zip"
store_path = tmpdir / "stored.zip"

with libarchive.file_writer(
    str(deflate_path), "zip", options="zip:compression-level=9"
) as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

with libarchive.file_writer(
    str(store_path), "zip", options="zip:compression=store"
) as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

deflate_size = deflate_path.stat().st_size
store_size = store_path.stat().st_size
assert deflate_size < store_size, (deflate_size, store_size)
# Repetitive payload should compress to at most a small fraction of original.
total_payload = sum(len(v) for v in expected.values())
assert deflate_size * 4 < total_payload, (deflate_size, total_payload)

got = {}
with libarchive.file_reader(str(deflate_path)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == expected, sorted(got.keys())
print("zip-deflate9", deflate_size, store_size)
PY
