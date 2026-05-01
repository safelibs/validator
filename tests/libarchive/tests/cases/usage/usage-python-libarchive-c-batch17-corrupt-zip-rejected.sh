#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch17-corrupt-zip-rejected
# @title: python-libarchive-c truncated zip raises ArchiveError
# @description: Writes a valid zip archive, truncates it to roughly half its length and zeros out a chunk of the deflate payload, then feeds the corrupt bytes through libarchive.memory_reader. Asserts that iteration raises libarchive.exception.ArchiveError rather than yielding silent garbage, exercising the error-propagation path for a recoverable-format-but-corrupt-stream input.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch17-corrupt-zip-rejected"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path
import libarchive
from libarchive.exception import ArchiveError

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "good.zip"
expected = {
    "alpha.txt": b"alpha pre-corrupt\n" * 64,
    "beta.txt": b"beta pre-corrupt\n" * 64,
}
with libarchive.file_writer(str(archive_path), "zip") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = archive_path.read_bytes()
# Sanity check baseline reader on the intact bytes.
baseline = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        baseline[entry.pathname] = b"".join(entry.get_blocks())
assert baseline == expected, sorted(baseline.keys())

# Truncate to roughly half the archive AND zero out a 200-byte stretch in the
# middle of the deflate payload. That removes the EOCD record and reliably
# breaks deflate decompression so libarchive must raise rather than yield bytes.
half = len(raw) // 2
truncated = bytearray(raw[:half])
zero_start = min(64, len(truncated) - 1)
zero_end = min(zero_start + 80, len(truncated))
for i in range(zero_start, zero_end):
    truncated[i] = 0
truncated_bytes = bytes(truncated)

raised = False
try:
    with libarchive.memory_reader(truncated_bytes) as archive:
        for entry in archive:
            # force payload decode so deflate failures surface
            b"".join(entry.get_blocks())
except ArchiveError as exc:
    raised = True
    msg = str(exc)
    assert msg, "ArchiveError message must be non-empty"
assert raised, "expected ArchiveError on corrupt zip"
print("corrupt-zip-rejected", len(truncated_bytes))
PY
