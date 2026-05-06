#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch19-zip-utf8-pathname-roundtrip
# @title: python-libarchive-c zip iteration on archive with file path containing utf-8
# @description: Writes a zip archive containing a single entry whose pathname has a non-ASCII UTF-8 character, then verifies file_reader iteration yields the exact same pathname.
# @timeout: 120
# @tags: usage, archive, zip, utf8
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
arc = tmpdir / "utf8.zip"
name = "café/menu.txt"
body = b"croissant\n"
with libarchive.file_writer(str(arc), "zip") as writer:
    writer.add_file_from_memory(name, len(body), body)

names = []
sizes = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        names.append(entry.pathname)
        sizes.append(entry.size)
print("names", ",".join(names))
print("sizes", ",".join(str(s) for s in sizes))
assert names == [name], names
assert sizes == [len(body)], sizes
PY
