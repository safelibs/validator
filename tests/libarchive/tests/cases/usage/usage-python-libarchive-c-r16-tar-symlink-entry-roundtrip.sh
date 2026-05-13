#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r16-tar-symlink-entry-roundtrip
# @title: python-libarchive-c ustar with a symlink entry exposes issym/isfile on readback
# @description: Builds a ustar archive on disk from a regular file plus a real on-disk symlink to it via libarchive.file_writer.add_files, reads the archive back via libarchive.file_reader, and asserts the regular entry reports .issym is False/.isfile is True while the link entry reports .issym is True and .linkname points to the target basename — exercising the filetype propagation path on ustar.
# @timeout: 180
# @tags: usage, archive, ustar, symlink
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

stage="$tmpdir/stage"
mkdir -p "$stage"
printf 'r16 ustar symlink target payload\n' >"$stage/regular.txt"
ln -s regular.txt "$stage/link.txt"

python3 - <<'PY' "$tmpdir" "$stage"
import sys
from pathlib import Path

import libarchive

tmpdir = Path(sys.argv[1])
stage = Path(sys.argv[2])

archive_path = tmpdir / "out.tar"
with libarchive.file_writer(str(archive_path), format_name="ustar", filter_name=None) as writer:
    writer.add_files(str(stage / "regular.txt"), str(stage / "link.txt"))

found = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        key = entry.pathname.rsplit("/", 1)[-1]
        found[key] = {
            "issym": entry.issym,
            "isfile": entry.isfile,
            "linkname": entry.linkname or "",
        }
        # Drain the entry body
        b"".join(entry.get_blocks())

assert "regular.txt" in found, found
assert "link.txt" in found, found
assert found["regular.txt"]["issym"] is False, found["regular.txt"]
assert found["regular.txt"]["isfile"] is True, found["regular.txt"]
assert found["link.txt"]["issym"] is True, found["link.txt"]
assert found["link.txt"]["linkname"] == "regular.txt", found["link.txt"]
print("ustar-symlink-ok", found)
PY
