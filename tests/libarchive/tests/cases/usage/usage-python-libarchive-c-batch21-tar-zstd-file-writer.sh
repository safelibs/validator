#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch21-tar-zstd-file-writer
# @title: python-libarchive-c file_writer wraps tar payload in zstd container
# @description: Writes a single ustar entry through file_writer using filter_name="zstd" and confirms the output begins with the zstd magic bytes (28 B5 2F FD) and reads back the exact payload via file_reader, exercising the zstd-write filter as opposed to the existing zstd memory-reader and size-check cases.
# @timeout: 120
# @tags: usage, archive, zstd, filter
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
from pathlib import Path
import sys
import libarchive

tmpdir = Path(sys.argv[1])
arc = tmpdir / "out.tar.zst"
payload = b"zstd-filter-payload-bytes\n"

with libarchive.file_writer(str(arc), "ustar", "zstd") as writer:
    writer.add_file_from_memory("z.txt", len(payload), payload)

magic = arc.read_bytes()[:4]
assert magic == b"\x28\xb5\x2f\xfd", magic.hex()

seen = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen.append((entry.pathname, b"".join(entry.get_blocks())))

assert seen == [("z.txt", payload)], seen
print("zstd-roundtrip", len(arc.read_bytes()))
PY
