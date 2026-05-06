#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch19-tar-mode-0644-roundtrip
# @title: python-libarchive-c tar entry mode 0644 roundtrip
# @description: Creates a tar archive from a 0o644 file on disk and verifies the entry's mode low 9 bits read back as 0o644.
# @timeout: 120
# @tags: usage, archive, tar, mode
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import sys
from pathlib import Path
import os
import libarchive

tmpdir = Path(sys.argv[1])
src = tmpdir / "f.txt"
src.write_text("payload\n")
os.chmod(src, 0o644)
arc = tmpdir / "out.tar"
cwd_before = os.getcwd()
os.chdir(tmpdir)
try:
    with libarchive.file_writer(str(arc), "gnutar") as writer:
        writer.add_files("f.txt")
finally:
    os.chdir(cwd_before)

modes = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        modes.append(entry.mode & 0o777)
print("modes", modes)
assert any(m == 0o644 for m in modes), f"expected 0o644 in {modes}"
PY
