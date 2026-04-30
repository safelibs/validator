#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch15-cpio-from-disk
# @title: python-libarchive-c file_writer cpio with on-disk source files
# @description: Stages a small directory of regular files on disk, then opens a python-libarchive-c file_writer in the cpio (newc) format and feeds each on-disk file in via writer.add_files. Reads the resulting cpio archive back through file_reader and verifies that every staged file is present with its original payload bytes. Exercises the file_writer.add_files convenience API alongside cpio so it complements the existing in-memory cpio cases.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch15-cpio-from-disk"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

stage="$tmpdir/stage"
mkdir -p "$stage"
printf 'first cpio payload\n' >"$stage/first.txt"
printf 'second cpio payload bytes\n' >"$stage/second.txt"
printf 'third cpio payload, somewhat longer than the others\n' >"$stage/third.txt"

python3 - <<'PY' "$case_id" "$tmpdir" "$stage"
import os
import sys
from pathlib import Path

import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
stage = Path(sys.argv[3])

archive_path = tmpdir / "out.cpio"
sources = ["first.txt", "second.txt", "third.txt"]

# add_files honours cwd, so chdir into the staging directory so the entries
# land with their basenames rather than absolute paths.
prev = Path.cwd()
os.chdir(stage)
try:
    with libarchive.file_writer(str(archive_path), "cpio") as writer:
        writer.add_files(*sources)
finally:
    os.chdir(prev)

# Sanity: libarchive's default "cpio" format emits the POSIX.1-1988 (odc) variant
# whose ASCII magic is "070707".
assert archive_path.read_bytes()[:6] == b"070707", archive_path.read_bytes()[:6]

got = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        if entry.isreg:
            got[entry.pathname] = b"".join(entry.get_blocks())
        else:
            b"".join(entry.get_blocks())

for name in sources:
    assert name in got, (name, sorted(got))
    assert got[name] == (stage / name).read_bytes(), (name, len(got[name]))
print("cpio-from-disk", sorted(got))
PY
