#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r17-tar-symlink-and-regular-mix-iter
# @title: python-libarchive-c ustar with a regular and a symlink mixed iterates both entry kinds
# @description: Builds a ustar archive on disk by feeding libarchive.file_writer.add_files a real regular file plus a real symlink in the same call, reads it back via libarchive.file_reader, and asserts the regular entry reports .isfile True with .issym False while the symlink entry reports .issym True and .linkname pointing to the regular basename.
# @timeout: 90
# @tags: usage, archive, ustar, symlink, mixed
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

stage="$tmpdir/stage"
mkdir -p "$stage"
printf 'r17 mixed regular payload\n' >"$stage/regfile.txt"
ln -s regfile.txt "$stage/aliaslink.txt"

python3 - <<'PY' "$tmpdir" "$stage"
import sys
from pathlib import Path
import libarchive

tmpdir = Path(sys.argv[1])
stage = Path(sys.argv[2])

arc = tmpdir / "out.tar"
with libarchive.file_writer(str(arc), format_name="ustar", filter_name=None) as writer:
    writer.add_files(str(stage / "regfile.txt"), str(stage / "aliaslink.txt"))

found = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        key = entry.pathname.rsplit("/", 1)[-1]
        found[key] = {
            "issym": entry.issym,
            "isfile": entry.isfile,
            "linkname": entry.linkname or "",
        }
        b"".join(entry.get_blocks())

assert "regfile.txt" in found, found
assert "aliaslink.txt" in found, found
assert found["regfile.txt"]["issym"] is False, found["regfile.txt"]
assert found["regfile.txt"]["isfile"] is True, found["regfile.txt"]
assert found["aliaslink.txt"]["issym"] is True, found["aliaslink.txt"]
assert found["aliaslink.txt"]["linkname"] == "regfile.txt", found["aliaslink.txt"]
print("mix-ok", sorted(found))
PY
