#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch21-zip-twenty-entries-iter-count
# @title: python-libarchive-c zip with twenty entries iterates twenty times in insertion order
# @description: Writes 20 in-memory zip entries with deterministic pathnames via add_file_from_memory, then asserts file_reader iteration yields exactly 20 (pathname, payload) tuples in insertion order. Distinct from existing 12-entry cpio and 1000-entry tar count cases since it pins zip iteration on a small batch.
# @timeout: 120
# @tags: usage, archive, zip, iteration
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
from pathlib import Path
import sys
import libarchive

tmpdir = Path(sys.argv[1])
arc = tmpdir / "twenty.zip"
expected = [(f"e{i:02d}.txt", f"payload-{i}\n".encode()) for i in range(20)]

with libarchive.file_writer(str(arc), "zip") as writer:
    for name, body in expected:
        writer.add_file_from_memory(name, len(body), body)

seen = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen.append((entry.pathname, b"".join(entry.get_blocks())))

assert len(seen) == 20, len(seen)
assert seen == expected, ([n for n, _ in seen], [n for n, _ in expected])
print("zip-twenty", len(seen))
PY
