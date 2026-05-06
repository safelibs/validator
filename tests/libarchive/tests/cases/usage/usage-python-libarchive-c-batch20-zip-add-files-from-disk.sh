#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch20-zip-add-files-from-disk
# @title: python-libarchive-c zip writer add_files reads three on-disk files
# @description: Stages three small files in a tmpdir, then writes them into a zip archive via file_writer.add_files (positional paths), and verifies the resulting archive holds all three names with their original payload bytes when iterated. Complements existing zip cases which write entries via add_file_from_memory only.
# @timeout: 180
# @tags: usage, archive, zip
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
files = {
    "alpha.txt": b"alpha payload\n",
    "beta.txt": b"beta payload bytes\n",
    "gamma.bin": bytes(range(128)),
}
for name, body in files.items():
    (tmpdir / name).write_bytes(body)

arc = tmpdir / "from-disk.zip"
prev = os.getcwd()
os.chdir(tmpdir)
try:
    with libarchive.file_writer(str(arc), "zip") as writer:
        writer.add_files(*files.keys())
finally:
    os.chdir(prev)

raw = arc.read_bytes()
assert raw[:2] == b"PK", raw[:2]

got = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())

assert got == files, (sorted(got.keys()), sorted(files.keys()))
print("zip-from-disk", sorted(got.keys()))
PY
