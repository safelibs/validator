#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch14-ar-multi-member-explicit-names
# @title: python-libarchive-c ar bsd archive with explicit member filenames
# @description: Builds a BSD ar archive with five explicitly named members of varying sizes via add_file_from_memory and reads each one back, verifying the archive magic, the number of members, the exact member names (after stripping libarchive's BSD-format trailing slash), and the payload bytes. The existing ar svr4 test only covers two members and svr4 layout; this case targets the bsd layout and a richer member set.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch14-ar-multi-member-explicit-names"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

path = tmpdir / "members.a"
expected = {
    "alpha.o": b"\x7fELF-stub-alpha",
    "beta.o": b"\x7fELF-stub-beta-longer",
    "gamma.o": b"gamma payload bytes\n",
    "short.o": b"x",
    "biggish.o": b"Q" * 4096,
}

with libarchive.file_writer(str(path), "ar_bsd") as writer:
    for name, payload in expected.items():
        writer.add_file_from_memory(name, len(payload), payload)

raw = path.read_bytes()
assert raw.startswith(b"!<arch>\n"), raw[:8]

got = {}
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        # ar member names sometimes come back with a trailing '/'.
        name = entry.pathname.rstrip("/")
        got[name] = b"".join(entry.get_blocks())

assert set(got) == set(expected), (sorted(got), sorted(expected))
for name, payload in expected.items():
    assert got[name] == payload, (name, len(got[name]), len(payload))
print("ar-bsd-multi", len(got))
PY
