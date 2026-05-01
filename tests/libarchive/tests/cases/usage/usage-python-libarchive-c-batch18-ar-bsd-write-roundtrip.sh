#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch18-ar-bsd-write-roundtrip
# @title: python-libarchive-c ar BSD format roundtrip
# @description: Writes a 4.4BSD-style Unix archive via libarchive.file_writer with format_name="ar_bsd" (the BSD ar variant, distinct from the existing ar_svr4 case), asserts the file begins with the canonical "!<arch>\n" magic, and reads each member back through libarchive.file_reader confirming the per-member payloads round trip byte-for-byte. ar_bsd uses the #1/<len> long-name extension when a member name overflows the 16-byte ar header field, so a deliberately long member name is included to exercise that path.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch18-ar-bsd-write-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
from pathlib import Path
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

archive_path = tmpdir / "out.a"
expected = {
    "short.o": b"\x7fELF-stub-short",
    # > 16 chars to trigger the BSD #1/<len> long-name encoding.
    "very-long-member-name.o": b"\x7fELF-stub-long-payload",
}

with libarchive.file_writer(str(archive_path), "ar_bsd") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = archive_path.read_bytes()
assert raw.startswith(b"!<arch>\n"), raw[:16]
# BSD long-name extension marker.
assert b"#1/" in raw, raw[:128]

got = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())

assert got == expected, sorted(got.keys())
print("ar_bsd", len(raw), sorted(got.keys()))
PY
