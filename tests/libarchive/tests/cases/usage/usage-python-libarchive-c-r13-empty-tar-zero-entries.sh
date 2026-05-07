#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r13-empty-tar-zero-entries
# @title: python-libarchive-c empty ustar archive iterates as zero entries
# @description: Writes a ustar archive with no entries via file_writer (open and close immediately), then opens it through file_reader and verifies the iteration produces zero entries and the file is non-empty (tar end-of-archive blocks present).
# @timeout: 60
# @tags: usage, archive, tar, empty
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
arc = tmpdir / "empty.tar"

with libarchive.file_writer(str(arc), "ustar") as writer:
    pass  # zero entries

raw = arc.read_bytes()
# tar end-of-archive is two zeroed 512-byte records; payload should still be
# non-empty and a multiple of 512.
assert len(raw) > 0, len(raw)
assert len(raw) % 512 == 0, len(raw)
assert raw == b"\x00" * len(raw), "expected all-zero end-of-archive padding"

count = 0
with libarchive.file_reader(str(arc)) as archive:
    for _ in archive:
        count += 1

assert count == 0, count
print("empty-tar", len(raw), count)
PY
