#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch17-memory-writer-bytes
# @title: python-libarchive-c memory_writer to BytesIO
# @description: Builds a gnutar archive entirely in memory by passing a BytesIO buffer to libarchive.memory_writer, then re-parses the resulting bytes through libarchive.memory_reader. Confirms that the in-memory writer code path (no on-disk file) produces a stream that round trips through the memory_reader and recovers every entry pathname plus its payload exactly.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch17-memory-writer-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import io
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

expected = {
    "alpha.txt": b"alpha in memory\n" * 8,
    "nested/beta.txt": b"beta in memory bytes\n" * 16,
    "gamma.bin": bytes(range(128)),
}

buf = io.BytesIO()
with libarchive.memory_writer(buf, "gnutar") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = buf.getvalue()
assert len(raw) > 0, len(raw)
# tar streams must be a non-empty multiple of 512 bytes per the ustar spec.
assert len(raw) % 512 == 0, len(raw)

got = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == expected, sorted(got.keys())
print("memory-writer-bytes", len(raw), len(got))
PY
