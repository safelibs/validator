#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch17-corrupt-zip-rejected
# @title: python-libarchive-c truncated zip raises ArchiveError
# @description: Writes a valid zip archive, truncates it before the end-of-central-directory record, and feeds the truncated bytes through libarchive.memory_reader. Asserts that iteration raises libarchive.exception.ArchiveError rather than yielding silent garbage, exercising the error-propagation path for a recoverable-format-but-corrupt-stream input.
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

# Drop the final 32 bytes so the EOCD record is missing, plus blank out an
# in-stream local file header signature to guarantee the parser fails.
truncated = bytearray(raw[:-32])
sig = b"PK\x03\x04"
idx = truncated.find(sig, 64)
assert idx > 0, idx
truncated[idx:idx + 4] = b"XXXX"
truncated_bytes = bytes(truncated)

raised = False
try:
    with libarchive.memory_reader(truncated_bytes) as archive:
        for _ in archive:
            pass
except ArchiveError as exc:
    raised = True
    msg = str(exc)
    assert msg, "ArchiveError message must be non-empty"
assert raised, "expected ArchiveError on corrupt zip"
print("corrupt-zip-rejected", len(truncated_bytes))
PY
