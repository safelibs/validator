#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r16-mtree-format-roundtrip
# @title: python-libarchive-c file_writer(mtree) emits mtree text consumable by file_reader
# @description: Builds an mtree manifest via libarchive.file_writer(format_name='mtree', filter_name=None) listing three entries, asserts the on-disk output begins with the literal "#mtree" sigil, then reads it back via libarchive.file_reader and confirms every pathname appears in the iteration set — exercising the mtree writer/reader pair end-to-end.
# @timeout: 180
# @tags: usage, archive, mtree
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
archive_path = tmpdir / "out.mtree"

names = ["alpha.txt", "nested/beta.txt", "gamma.bin"]

with libarchive.file_writer(str(archive_path), format_name="mtree", filter_name=None) as writer:
    for n in names:
        body = ("r16 mtree " + n).encode()
        writer.add_file_from_memory(n, len(body), body)

text = archive_path.read_bytes()
assert text.startswith(b"#mtree"), text[:32]

got = []
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        got.append(entry.pathname.lstrip("./"))

for n in names:
    assert n in got, (n, got)
print("mtree-ok", got)
PY
