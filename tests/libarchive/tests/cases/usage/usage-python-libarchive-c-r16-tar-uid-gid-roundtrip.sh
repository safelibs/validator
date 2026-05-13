#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r16-tar-uid-gid-roundtrip
# @title: python-libarchive-c ustar entry preserves uid/gid across in-memory round-trip
# @description: Builds a ustar archive on disk from a real file whose owner/group are the current process uid/gid via libarchive.file_writer with add_files, then reads it back via libarchive.file_reader and asserts every entry's .uid and .gid match the current os.getuid()/os.getgid(), exercising the ownership-metadata propagation path.
# @timeout: 180
# @tags: usage, archive, ustar, uid, gid
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import os
import sys
from pathlib import Path

import libarchive

tmpdir = Path(sys.argv[1])
src = tmpdir / "src"
src.mkdir()
(src / "alpha.txt").write_bytes(b"r16 uid/gid alpha\n")
(src / "beta.txt").write_bytes(b"r16 uid/gid beta\n")

archive_path = tmpdir / "out.tar"
with libarchive.file_writer(str(archive_path), format_name="ustar", filter_name=None) as writer:
    writer.add_files(str(src / "alpha.txt"), str(src / "beta.txt"))

my_uid = os.getuid()
my_gid = os.getgid()

seen = 0
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        assert entry.uid == my_uid, (entry.pathname, entry.uid, my_uid)
        assert entry.gid == my_gid, (entry.pathname, entry.gid, my_gid)
        seen += 1

assert seen == 2, seen
print("uid-gid-ok", my_uid, my_gid, seen)
PY
