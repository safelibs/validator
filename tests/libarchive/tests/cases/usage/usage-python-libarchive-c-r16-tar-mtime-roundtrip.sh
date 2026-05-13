#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r16-tar-mtime-roundtrip
# @title: python-libarchive-c ustar entry preserves mtime to the second across round-trip
# @description: Creates a regular file, sets its mtime to a known epoch value 1700000000 via os.utime, packs it into a ustar archive via libarchive.file_writer.add_files, reads back via libarchive.file_reader, and asserts the entry .mtime equals the stored epoch second, exercising ustar's whole-second mtime fidelity.
# @timeout: 180
# @tags: usage, archive, ustar, mtime
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
target = src / "stamped.txt"
target.write_bytes(b"r16 mtime payload\n")

stamp = 1700000000
os.utime(str(target), (stamp, stamp))

archive_path = tmpdir / "out.tar"
with libarchive.file_writer(str(archive_path), format_name="ustar", filter_name=None) as writer:
    writer.add_files(str(target))

found = []
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        m = entry.mtime
        if isinstance(m, tuple):
            sec = int(m[0])
        else:
            sec = int(m)
        found.append((entry.pathname, sec))

assert len(found) == 1, found
_, got_mtime = found[0]
assert got_mtime == stamp, (got_mtime, stamp)
print("mtime-ok", got_mtime)
PY
