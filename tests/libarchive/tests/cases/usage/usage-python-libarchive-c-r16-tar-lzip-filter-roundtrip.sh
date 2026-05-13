#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r16-tar-lzip-filter-roundtrip
# @title: python-libarchive-c file_writer(ustar, filter='lzip') round-trips through file_reader
# @description: Builds a tar.lz archive via libarchive.file_writer(format_name='ustar', filter_name='lzip') with two entries, asserts the on-disk magic is "LZIP", and reads them back via libarchive.file_reader confirming every pathname/payload pair matches — exercising the ustar+lzip filter chain.
# @timeout: 180
# @tags: usage, archive, tar, lzip, filter
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
archive_path = tmpdir / "out.tar.lz"

expected = {
    "alpha.txt": b"r16 lzip alpha payload\n" * 4,
    "delta/echo.bin": bytes(range(80)),
}

with libarchive.file_writer(str(archive_path), format_name="ustar", filter_name="lzip") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = archive_path.read_bytes()
assert raw[:4] == b"LZIP", raw[:4]

got = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())

assert got == expected, sorted(got)
print("tar-lzip-ok", archive_path.stat().st_size)
PY
