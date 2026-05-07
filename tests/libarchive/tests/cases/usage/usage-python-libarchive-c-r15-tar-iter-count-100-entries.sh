#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r15-tar-iter-count-100-entries
# @title: python-libarchive-c iterates exactly 100 entries from a generated tar
# @description: Writes a ustar archive containing 100 entries with deterministic names (entry-000.txt .. entry-099.txt) via file_writer.add_file_from_memory, then iterates the archive with file_reader and asserts the iteration yields exactly 100 entries in insertion order with payload bytes matching the index-encoded body. Distinct from earlier 50/256/1000/5000-entry counts in batches 12/15/19/r12.
# @timeout: 180
# @tags: usage, archive, tar, iter-count
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import sys
from pathlib import Path

import libarchive

tmpdir = Path(sys.argv[1])
arc = tmpdir / "100.tar"

expected = []
for i in range(100):
    name = f"entry-{i:03d}.txt"
    body = f"r15 entry index={i:03d} payload\n".encode("ascii")
    expected.append((name, body))

with libarchive.file_writer(str(arc), "ustar") as writer:
    for name, body in expected:
        writer.add_file_from_memory(name, len(body), body)

seen = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen.append((entry.pathname, b"".join(entry.get_blocks())))

assert len(seen) == 100, len(seen)
assert seen == expected, [(n, len(b)) for n, b in seen[:3]]
print("iter-count-100", len(seen))
PY
