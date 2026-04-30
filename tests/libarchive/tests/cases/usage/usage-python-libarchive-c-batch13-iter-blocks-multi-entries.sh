#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch13-iter-blocks-multi-entries
# @title: python-libarchive-c iter get_blocks across multiple entries
# @description: Writes a tar archive with three large entries and consumes each entry's payload by iterating get_blocks() one chunk at a time, asserting block-count > 0 and accumulated bytes equal the original payload size for every member.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch13-iter-blocks-multi-entries"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

path = tmpdir / "blocks.tar"
expected = {
    "small.bin": b"x" * 100,
    "medium.bin": b"y" * (64 * 1024),
    "large.bin": b"z" * (256 * 1024 + 7),
}

with libarchive.file_writer(str(path), "gnutar") as writer:
    for name, data in expected.items():
        writer.add_file_from_memory(name, len(data), data)

stats = {}
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        block_count = 0
        seen = bytearray()
        # Stream each entry one block at a time; do not collapse to a single
        # b"".join(...) so we exercise the iterator across multiple calls.
        for block in entry.get_blocks():
            block_count += 1
            seen.extend(block)
        stats[entry.pathname] = (block_count, bytes(seen))

assert sorted(stats.keys()) == sorted(expected.keys()), stats.keys()
for name, payload in expected.items():
    block_count, seen = stats[name]
    assert block_count >= 1, (name, block_count)
    assert seen == payload, (name, len(seen), len(payload))

# At least one entry must take multiple blocks for the streaming path to be
# meaningfully exercised.
multi = [name for name, (count, _) in stats.items() if count > 1]
assert multi, stats
print("iter-blocks", {name: count for name, (count, _) in stats.items()})
PY
