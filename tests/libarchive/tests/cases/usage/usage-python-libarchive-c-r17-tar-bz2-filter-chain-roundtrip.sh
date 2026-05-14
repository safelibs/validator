#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r17-tar-bz2-filter-chain-roundtrip
# @title: python-libarchive-c ustar with bzip2 filter round-trips on disk
# @description: Builds a ustar archive via libarchive.file_writer with filter_name="bzip2", writes three entries to it, and reads the file back via libarchive.file_reader asserting every pathname and payload matches insertion order, exercising the bzip2 filter chain on a file-backed writer.
# @timeout: 120
# @tags: usage, archive, tar, bzip2
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
arc = tmpdir / "out.tar.bz2"

expected = {
    "first.txt": b"r17 bz2 entry 1\n",
    "second.txt": b"r17 bz2 entry 2 with more bytes\n",
    "third.bin": bytes(range(64)),
}
order = ["first.txt", "second.txt", "third.bin"]

with libarchive.file_writer(str(arc), format_name="ustar", filter_name="bzip2") as writer:
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
print("tar-bz2-ok", got_order)
PY
