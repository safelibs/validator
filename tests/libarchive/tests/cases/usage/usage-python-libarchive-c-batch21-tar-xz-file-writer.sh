#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch21-tar-xz-file-writer
# @title: python-libarchive-c file_writer wraps tar payload in xz container
# @description: Writes a single ustar entry through file_writer using filter_name="xz" and confirms the resulting file begins with the xz magic bytes (FD 37 7A 58 5A 00) and reads back the original payload via file_reader, exercising the xz-write filter independently from the bzip2-detection case in batch15.
# @timeout: 120
# @tags: usage, archive, xz, filter
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
arc = tmpdir / "out.tar.xz"
payload = b"xz-filter-payload\n"

with libarchive.file_writer(str(arc), "ustar", "xz") as writer:
    writer.add_file_from_memory("p.txt", len(payload), payload)

magic = arc.read_bytes()[:6]
assert magic == b"\xfd7zXZ\x00", magic.hex()

seen = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen.append((entry.pathname, b"".join(entry.get_blocks())))

assert seen == [("p.txt", payload)], seen
print("xz-roundtrip", len(arc.read_bytes()))
PY
