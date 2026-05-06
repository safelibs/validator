#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch20-tar-pathname-dot-prefix-roundtrip
# @title: python-libarchive-c tar entries with leading "./" pathname survive roundtrip
# @description: Writes three ustar entries whose pathnames start with the leading "./" convention emitted by GNU tar, then iterates the archive and asserts every read-back pathname matches the input verbatim (including the dot-slash prefix) with payload bytes intact.
# @timeout: 120
# @tags: usage, archive, tar, pathname
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
from pathlib import Path
import sys
import libarchive

tmpdir = Path(sys.argv[1])
arc = tmpdir / "dotprefix.tar"
expected = {
    "./alpha.txt": b"alpha-with-dot\n",
    "./sub/beta.txt": b"beta-nested\n",
    "./gamma.bin": bytes(range(32)),
}

with libarchive.file_writer(str(arc), "ustar") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

got = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())

assert got == expected, (sorted(got.keys()), sorted(expected.keys()))
print("tar-dotprefix", sorted(got.keys()))
PY
