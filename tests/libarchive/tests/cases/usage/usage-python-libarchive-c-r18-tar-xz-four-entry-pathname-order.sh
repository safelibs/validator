#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r18-tar-xz-four-entry-pathname-order
# @title: python-libarchive-c ustar with xz filter preserves four-entry pathname order
# @description: Builds a ustar archive on disk via libarchive.file_writer with filter_name="xz" containing four entries inserted in a non-alphabetical order, reads back via libarchive.file_reader, and asserts the iteration pathname sequence equals the original insertion order, exercising the xz filter on a four-entry on-disk archive.
# @timeout: 120
# @tags: usage, archive, ustar, xz, order, r18
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
arc = tmpdir / "out.tar.xz"
order = ["zeta.bin", "alpha.txt", "middle.dat", "kilo.log"]
data = {n: ("r18-xz-" + n).encode() + b"-payload\n" for n in order}

with libarchive.file_writer(str(arc), format_name="ustar", filter_name="xz") as writer:
    for n in order:
        writer.add_file_from_memory(n, len(data[n]), data[n])

got_order = []
got = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        got_order.append(entry.pathname)
        got[entry.pathname] = b"".join(entry.get_blocks())

assert got_order == order, (got_order, order)
assert got == data
print("xz-order-ok", got_order)
PY
