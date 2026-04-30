#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch15-tar-tiny-single-entry
# @title: python-libarchive-c tar single entry under 100 bytes
# @description: Writes a gnutar archive containing exactly one entry whose payload is 47 bytes (well under 100), then reads it back and verifies the iterator yields exactly one entry with the declared pathname, size, and payload. Sanity-checks that a sub-block-size payload still rounds out to a tar block boundary on disk so the writer is padding correctly.
# @timeout: 120
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch15-tar-tiny-single-entry"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "tiny.tar"
name = "tiny.txt"
payload = b"sub-100-byte payload for the tiny entry case\n"
assert len(payload) < 100, len(payload)

with libarchive.file_writer(str(archive_path), "gnutar") as writer:
    writer.add_file_from_memory(name, len(payload), payload)

# tar block size is 512 and gnutar pads the archive to a multiple of that.
total = archive_path.stat().st_size
assert total % 512 == 0, total
# Header (512) + payload block (512) + at least one zero-record trailer block.
assert total >= 512 * 3, total

records = []
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        records.append((entry.pathname, entry.size, b"".join(entry.get_blocks())))

assert records == [(name, len(payload), payload)], records
print("tiny-single", total)
PY
