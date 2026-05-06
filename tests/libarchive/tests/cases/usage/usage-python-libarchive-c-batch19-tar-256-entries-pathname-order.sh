#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch19-tar-256-entries-pathname-order
# @title: python-libarchive-c tar 256 entries preserve insertion order
# @description: Writes a tar archive with 256 entries, then reads it back and verifies the iteration order matches insertion order exactly.
# @timeout: 180
# @tags: usage, archive, tar
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
arc = tmpdir / "many.tar"
expected = [f"entry-{i:04x}.dat" for i in range(256)]

with libarchive.file_writer(str(arc), "gnutar") as writer:
    for n in expected:
        writer.add_file_from_memory(n, 1, b"x")

names = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        names.append(entry.pathname)

print("count", len(names))
print("first", names[0])
print("last", names[-1])
assert names == expected, "order mismatch"
PY
