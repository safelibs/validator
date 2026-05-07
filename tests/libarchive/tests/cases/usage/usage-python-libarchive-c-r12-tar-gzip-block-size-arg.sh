#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r12-tar-gzip-block-size-arg
# @title: python-libarchive-c file_reader respects an explicit block_size kwarg
# @description: Writes a small ustar+gzip archive, then opens it with file_reader(block_size=4096) and confirms iteration still yields the inserted entries with their payloads. Exercises the optional block_size kwarg distinct from the default-block reader cases.
# @timeout: 120
# @tags: usage, archive, tar, gzip, block-size
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
    "block/one.txt": b"first block payload\n",
    "block/two.txt": b"second block payload bytes\n",
}

with libarchive.file_writer(str(arc), "ustar", "gzip") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

magic = arc.read_bytes()[:2]
assert magic == b"\x1f\x8b", magic.hex()

seen = {}
with libarchive.file_reader(str(arc), block_size=4096) as archive:
    for entry in archive:
        seen[entry.pathname] = b"".join(entry.get_blocks())

assert seen == expected, (sorted(seen), sorted(expected))
print("block-size", 4096, sorted(seen))
PY
