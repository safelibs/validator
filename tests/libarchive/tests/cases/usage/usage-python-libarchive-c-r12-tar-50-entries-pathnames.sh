#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r12-tar-50-entries-pathnames
# @title: python-libarchive-c tar archive with 50 entries iterates pathnames in insertion order
# @description: Writes 50 in-memory entries with deterministic zero-padded names into a single ustar archive and confirms file_reader iteration yields exactly 50 pathnames in insertion order. Distinct from the 12-entry cpio, 20-entry zip, 256-entry tar, and 1000-entry tar count cases as it pins iteration on a 50-entry batch.
# @timeout: 120
# @tags: usage, archive, tar, iteration
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
arc = tmpdir / "fifty.tar"
expected_names = [f"e{i:03d}.txt" for i in range(50)]

with libarchive.file_writer(str(arc), "ustar") as writer:
    for name in expected_names:
        body = name.encode() + b"\n"
        writer.add_file_from_memory(name, len(body), body)

seen = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen.append(entry.pathname)
        b"".join(entry.get_blocks())

assert len(seen) == 50, len(seen)
assert seen == expected_names, (seen[:5], expected_names[:5])
print("tar-fifty", len(seen))
PY
