#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r18-tar-gz-three-entry-iter-count
# @title: python-libarchive-c gnutar with gzip filter exposes three entries on iteration
# @description: Builds a gnutar archive on disk via libarchive.file_writer with filter_name="gzip" containing three named entries, then reads it back with libarchive.file_reader and asserts iteration yields exactly three entries whose pathnames match the writer's order, exercising the gnutar gzip filter on a file-backed reader.
# @timeout: 90
# @tags: usage, archive, gnutar, gzip, r18
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
order = ["alpha.txt", "beta.txt", "gamma.bin"]
data = {
    "alpha.txt": b"r18 alpha\n",
    "beta.txt": b"r18 beta with more bytes\n",
    "gamma.bin": bytes(range(48)),
}

with libarchive.file_writer(str(arc), format_name="gnutar", filter_name="gzip") as writer:
    for n in order:
        writer.add_file_from_memory(n, len(data[n]), data[n])

names = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        names.append(entry.pathname)
        b"".join(entry.get_blocks())

assert names == order, (names, order)
print("gnutar-gzip-ok", names)
PY
