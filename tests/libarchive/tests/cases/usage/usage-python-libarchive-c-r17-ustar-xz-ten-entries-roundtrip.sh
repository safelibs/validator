#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r17-ustar-xz-ten-entries-roundtrip
# @title: python-libarchive-c ustar with xz filter round-trips 10 entries on disk
# @description: Builds a ustar archive via libarchive.file_writer with filter_name="xz" containing ten entries named e00.txt..e09.txt, reads it back via libarchive.file_reader, and asserts the iteration produces exactly ten entries in insertion order with matching payloads, exercising xz compression at a moderate entry count.
# @timeout: 120
# @tags: usage, archive, ustar, xz, scale
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

names = [f"e{i:02d}.txt" for i in range(10)]
expected = {n: (f"r17 ustar+xz entry {n} payload\n").encode() for n in names}

with libarchive.file_writer(str(arc), format_name="ustar", filter_name="xz") as writer:
    for n in names:
        body = expected[n]
        writer.add_file_from_memory(n, len(body), body)

got_order = []
got = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        got_order.append(entry.pathname)
        got[entry.pathname] = b"".join(entry.get_blocks())

assert got_order == names, (got_order, names)
assert got == expected, sorted(got)
print("ustar-xz-ten-ok", len(got_order))
PY
