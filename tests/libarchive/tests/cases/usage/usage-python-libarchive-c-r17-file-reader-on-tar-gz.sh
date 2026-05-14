#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r17-file-reader-on-tar-gz
# @title: python-libarchive-c file_reader iterates a tar.gz produced by file_writer
# @description: Writes a small ustar+gzip archive to disk via libarchive.file_writer with filter_name="gzip", then opens the archive path via libarchive.file_reader and asserts the iteration produces exactly the entries written in insertion order, exercising the gzip filter on file-backed I/O.
# @timeout: 90
# @tags: usage, archive, tar, gzip, file-reader
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
arc = tmpdir / "out.tar.gz"

expected = {
    "x.txt": b"r17 gz x payload\n",
    "y.txt": b"r17 gz y payload more\n",
}
order = ["x.txt", "y.txt"]

with libarchive.file_writer(str(arc), format_name="ustar", filter_name="gzip") as writer:
    for n in order:
        body = expected[n]
        writer.add_file_from_memory(n, len(body), body)

got_order = []
got = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        got_order.append(entry.pathname)
        got[entry.pathname] = b"".join(entry.get_blocks())

assert got_order == order, (got_order, order)
assert got == expected, sorted(got)
print("tar-gz-ok", got_order)
PY
