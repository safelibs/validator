#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r16-tar-xz-filter-chain-roundtrip
# @title: python-libarchive-c file_writer(ustar, filter='xz') round-trips through file_reader
# @description: Builds a tar.xz archive via libarchive.file_writer(format_name='ustar', filter_name='xz') containing three entries with known payloads, reads them back via libarchive.file_reader, and asserts every (pathname, payload) pair matches the input — exercising the ustar+xz filter chain end-to-end.
# @timeout: 180
# @tags: usage, archive, tar, xz, filter
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
archive_path = tmpdir / "out.tar.xz"

expected = {
    "alpha.txt": b"r16 xz alpha payload\n" * 8,
    "nested/beta.bin": bytes(range(64)),
    "gamma.txt": b"r16 gamma\n",
}

with libarchive.file_writer(str(archive_path), format_name="ustar", filter_name="xz") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

# xz magic bytes: FD 37 7A 58 5A 00
raw = archive_path.read_bytes()
assert raw[:6] == b"\xfd7zXZ\x00", raw[:6]

got = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())

assert got == expected, sorted(got)
print("tar-xz-ok", archive_path.stat().st_size)
PY
