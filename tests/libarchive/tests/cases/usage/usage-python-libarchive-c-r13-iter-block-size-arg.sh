#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r13-iter-block-size-arg
# @title: python-libarchive-c file_reader honours an explicit block_size keyword
# @description: Writes a multi-entry ustar archive then opens it via file_reader(block_size=4096) and asserts the iteration still returns the full set of entries with intact payloads, exercising a non-default block_size argument on the read side.
# @timeout: 120
# @tags: usage, archive, tar, block-size
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
arc = tmpdir / "block.tar"
expected = {
    "a.txt": b"alpha body\n",
    "b.txt": b"beta body bytes\n",
    "c.bin": bytes(range(32)) * 4,
}

with libarchive.file_writer(str(arc), "ustar") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

# Default block size is 10240; pick a different power-of-two to exercise the kwarg.
seen = {}
with libarchive.file_reader(str(arc), block_size=4096) as archive:
    for entry in archive:
        seen[entry.pathname] = b"".join(entry.get_blocks())

assert seen == expected, (sorted(seen), sorted(expected))
print("block-size", len(seen))
PY
