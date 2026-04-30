#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-tar-deep-tree-many-levels
# @title: python-libarchive-c tar deep tree many levels
# @description: Roundtrips a deeply nested directory hierarchy through python-libarchive-c and verifies the path order.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-tar-deep-tree-many-levels"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "deep.tar"
levels = 12
prefix_parts = [f"lvl{i:02d}" for i in range(levels)]
nested_path = "/".join(prefix_parts) + "/leaf.txt"
peer_path = "/".join(prefix_parts[:6]) + "/midfile.txt"

ordered = [
    (peer_path, b"midfile body\n"),
    (nested_path, b"deep leaf body\n"),
]

with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    for name, body in ordered:
        writer.add_file_from_memory(name, len(body), body)

names = []
bodies = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        names.append(entry.pathname)
        bodies[entry.pathname] = b"".join(entry.get_blocks())

assert names == [peer_path, nested_path], names
assert bodies[nested_path] == b"deep leaf body\n"
assert bodies[peer_path] == b"midfile body\n"
assert nested_path.count("/") == levels  # 12 directory separators before leaf
print("deep-tree", levels, len(names))
PY
