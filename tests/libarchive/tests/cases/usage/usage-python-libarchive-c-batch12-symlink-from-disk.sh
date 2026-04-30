#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch12-symlink-from-disk
# @title: python-libarchive-c symlink from disk
# @description: Adds a real on-disk symlink via add_files and verifies entry.issym and linkname are preserved on read.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch12-symlink-from-disk"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

stage="$tmpdir/stage"
mkdir -p "$stage"
printf 'target payload\n' >"$stage/target.txt"
ln -s target.txt "$stage/link.txt"

python3 - <<'PY' "$case_id" "$tmpdir" "$stage"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
stage = Path(sys.argv[3])

archive_path = tmpdir / "with-symlink.tar"
with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    writer.add_files(str(stage / "target.txt"), str(stage / "link.txt"))

found = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        found[entry.pathname.lstrip("/")] = (entry.issym, entry.linkname or "")
        b"".join(entry.get_blocks())

target_key = next(k for k in found if k.endswith("target.txt"))
link_key = next(k for k in found if k.endswith("link.txt"))
assert found[target_key][0] is False, found[target_key]
assert found[link_key][0] is True, found[link_key]
assert found[link_key][1] == "target.txt", found[link_key]
print("symlink", len(found))
PY
