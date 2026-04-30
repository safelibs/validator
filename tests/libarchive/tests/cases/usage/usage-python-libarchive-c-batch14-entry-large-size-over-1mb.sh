#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch14-entry-large-size-over-1mb
# @title: python-libarchive-c iterate archive with entry.size > 1MB
# @description: Writes a ustar archive containing one entry whose payload is 2 MiB plus a small entry, then iterates and asserts entry.size matches the on-the-wire payload length for the >1 MiB entry exactly. The payload itself is consumed via get_blocks() inside the loop and its length is also verified independently of the header-declared size.
# @timeout: 240
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch14-entry-large-size-over-1mb"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

path = tmpdir / "large.tar"
big_size = 2 * 1024 * 1024 + 17  # > 1 MiB, deliberately not a block boundary
big_payload = (b"abcdefghij" * ((big_size // 10) + 1))[:big_size]
small_payload = b"smaller payload\n"

assert len(big_payload) == big_size

with libarchive.file_writer(str(path), "ustar") as writer:
    writer.add_file_from_memory("big.bin", len(big_payload), big_payload)
    writer.add_file_from_memory("tiny.txt", len(small_payload), small_payload)

records = []
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        # Stream-consume the payload; do not collapse to one read so we
        # actually exercise multi-block reads on the >1 MiB entry.
        seen = bytearray()
        block_count = 0
        for block in entry.get_blocks():
            block_count += 1
            seen.extend(block)
        records.append((entry.pathname, entry.size, block_count, bytes(seen)))

assert len(records) == 2, records
big = next(r for r in records if r[0] == "big.bin")
tiny = next(r for r in records if r[0] == "tiny.txt")

assert big[1] == big_size, (big[1], big_size)
assert big[1] > 1024 * 1024, big[1]
assert big[2] >= 2, big[2]
assert big[3] == big_payload, (len(big[3]), big_size)

assert tiny[1] == len(small_payload), tiny
assert tiny[3] == small_payload, tiny

print("large-size", big[1], big[2], len(records))
PY
