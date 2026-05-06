#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch20-cpio-twelve-entries-iter-count
# @title: python-libarchive-c cpio archive with twelve entries iterates twelve times
# @description: Writes 12 in-memory entries with deterministic pathnames into a single cpio archive via writer.add_file_from_memory and confirms file_reader iteration yields exactly 12 entries with their pathnames matching insertion order. Exercises a small-batch iteration count distinct from the existing single-entry and large-count cpio cases.
# @timeout: 120
# @tags: usage, archive, cpio, iteration
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
arc = tmpdir / "twelve.cpio"
expected = [(f"entry-{i:02d}.txt", f"payload {i}\n".encode()) for i in range(12)]

with libarchive.file_writer(str(arc), "cpio") as writer:
    for name, body in expected:
        writer.add_file_from_memory(name, len(body), body)

seen = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen.append((entry.pathname, b"".join(entry.get_blocks())))

assert len(seen) == 12, len(seen)
assert seen == expected, ([n for n, _ in seen], [n for n, _ in expected])
print("cpio-twelve", len(seen))
PY
