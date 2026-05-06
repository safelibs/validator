#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch19-tar-add-files-multiple-positional
# @title: python-libarchive-c tar add_files accepts multiple positional paths
# @description: Calls libarchive.file_writer.add_files with three positional file paths and verifies all three entries appear in the archive.
# @timeout: 120
# @tags: usage, archive, tar
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
files = ["alpha.txt", "beta.txt", "gamma.txt"]
for n in files:
    (tmpdir / n).write_text(f"{n}\n")

arc = tmpdir / "multi.tar"
cwd_before = os.getcwd()
os.chdir(tmpdir)
try:
    with libarchive.file_writer(str(arc), "gnutar") as writer:
        writer.add_files(*files)
finally:
    os.chdir(cwd_before)

names = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        names.append(entry.pathname)
print("names", ",".join(sorted(names)))
assert sorted(names) == sorted(files), names
PY
