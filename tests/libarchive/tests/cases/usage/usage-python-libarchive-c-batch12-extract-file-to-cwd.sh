#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch12-extract-file-to-cwd
# @title: python-libarchive-c extract_file to cwd
# @description: Builds a tar archive then unpacks it via libarchive.extract_file into a chdir'd directory and validates payloads on disk.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch12-extract-file-to-cwd"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import os
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "input.tar"
with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    writer.add_file_from_memory("alpha.txt", len(b"alpha\n"), b"alpha\n")
    writer.add_file_from_memory("nested/beta.txt", len(b"beta\n"), b"beta\n")

dest = tmpdir / "dest"
dest.mkdir()
prev = Path.cwd()
os.chdir(dest)
try:
    libarchive.extract_file(str(archive_path))
finally:
    os.chdir(prev)

assert (dest / "alpha.txt").read_bytes() == b"alpha\n"
assert (dest / "nested" / "beta.txt").read_bytes() == b"beta\n"
print("extract", sorted(p.name for p in dest.iterdir()))
PY
