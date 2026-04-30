#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch13-pax-directory-size-zero
# @title: python-libarchive-c pax directory entry size is zero
# @description: Writes a pax archive containing two explicit directory entries plus a regular file and verifies entry.size for each directory is exactly 0 while the file's size matches its payload.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch13-pax-directory-size-zero"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

path = tmpdir / "dirs.pax"
payload = b"file payload\n"
with libarchive.file_writer(str(path), "pax") as writer:
    writer.add_file_from_memory(
        "outer/", 0, b"", filetype=0o040000, permission=0o755
    )
    writer.add_file_from_memory(
        "outer/inner/", 0, b"", filetype=0o040000, permission=0o755
    )
    writer.add_file_from_memory(
        "outer/inner/data.bin", len(payload), payload
    )

sizes = {}
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        sizes[entry.pathname] = (entry.isdir, entry.size)
        b"".join(entry.get_blocks())

assert sizes.get("outer/", (None, None))[0] is True, sizes
assert sizes["outer/"][1] == 0, sizes
assert sizes["outer/inner/"][0] is True, sizes
assert sizes["outer/inner/"][1] == 0, sizes
assert sizes["outer/inner/data.bin"][0] is False, sizes
assert sizes["outer/inner/data.bin"][1] == len(payload), sizes
print("pax-dir-zero", sizes)
PY
