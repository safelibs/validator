#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch16-iter-blocks-large-block-size
# @title: python-libarchive-c get_blocks explicit block_size hint
# @description: Streams a large entry's payload via ArchiveEntry.get_blocks(block_size=131072) (passing an explicit block-size hint instead of the default page_size), verifies every yielded block is at most the requested size, and confirms the concatenated bytes match the original payload. Exercises the block_size keyword argument on the iterator.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch16-iter-blocks-large-block-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "blocks.tar"
# Use a payload large enough that even with a 128 KiB block hint, multiple
# blocks must be yielded.
payload = (b"large block-size hint payload\n" * 20_000)  # ~600 KiB
expected = {
    "small.bin": b"x" * 16,
    "large.bin": payload,
}
with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

block_hint = 128 * 1024
seen_blocks = {}
got = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        block_count = 0
        max_block = 0
        buf = bytearray()
        # Pass an explicit block_size hint distinct from the default page size.
        for block in entry.get_blocks(block_size=block_hint):
            block_count += 1
            if len(block) > max_block:
                max_block = len(block)
            assert len(block) <= block_hint, (entry.pathname, len(block))
            buf.extend(block)
        seen_blocks[entry.pathname] = (block_count, max_block)
        got[entry.pathname] = bytes(buf)

assert got == expected, sorted(got.keys())
# The large entry must require more than one block at the 128 KiB hint, and
# the largest observed block must not exceed the hint.
large_count, large_max = seen_blocks["large.bin"]
assert large_count > 1, seen_blocks
assert large_max <= block_hint, seen_blocks
print("iter-blocks-hint", seen_blocks)
PY
