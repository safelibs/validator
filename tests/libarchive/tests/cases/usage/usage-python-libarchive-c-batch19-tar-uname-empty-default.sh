#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch19-tar-uname-empty-default
# @title: python-libarchive-c tar reads file uid/gid from disk into entry
# @description: Creates a file on disk, archives it with libarchive.file_writer, and verifies the read-back entry uid/gid match the current process uid/gid.
# @timeout: 120
# @tags: usage, archive, tar, uid
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import sys
import os
from pathlib import Path
import libarchive

tmpdir = Path(sys.argv[1])
src = tmpdir / "f.txt"
src.write_text("payload\n")
arc = tmpdir / "ids.tar"
expected_uid = os.getuid()
expected_gid = os.getgid()

cwd_before = os.getcwd()
os.chdir(tmpdir)
try:
    with libarchive.file_writer(str(arc), "ustar") as writer:
        writer.add_files("f.txt")
finally:
    os.chdir(cwd_before)

ids = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        ids.append((entry.pathname, entry.uid, entry.gid))

print("ids", ids)
assert any(u == expected_uid and g == expected_gid for _, u, g in ids), f"expected uid={expected_uid} gid={expected_gid} in {ids}"
PY
