#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch14-nested-directory-depth-5
# @title: python-libarchive-c tar with nested directory depth 5
# @description: Constructs a tar archive carrying a single regular file at a deterministic nested path five components deep (a/b/c/d/e/leaf.txt) plus distractor entries at intermediate depths, then reads it back and asserts every nested path and payload survives. Exercises path handling for deeper trees than the existing nested-directory testcases (which top out at depth 3).
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch14-nested-directory-depth-5"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

path = tmpdir / "deep.tar"
expected = {
    "a/level1.txt": b"depth one\n",
    "a/b/level2.txt": b"depth two\n",
    "a/b/c/level3.txt": b"depth three\n",
    "a/b/c/d/level4.txt": b"depth four\n",
    "a/b/c/d/e/leaf.txt": b"five-deep leaf payload\n",
}

with libarchive.file_writer(str(path), "gnutar") as writer:
    for name, payload in expected.items():
        writer.add_file_from_memory(name, len(payload), payload)

got = {}
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())

assert got == expected, sorted(got)
deepest = "a/b/c/d/e/leaf.txt"
assert deepest in got, sorted(got)
assert deepest.count("/") == 5, deepest
print("nested-depth-5", len(got))
PY
