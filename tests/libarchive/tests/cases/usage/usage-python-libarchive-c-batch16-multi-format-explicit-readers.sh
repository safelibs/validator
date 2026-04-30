#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch16-multi-format-explicit-readers
# @title: python-libarchive-c multi-format readers via explicit format_name
# @description: Writes three archives in distinct container formats (gnutar, zip, cpio) and reads each one back through file_reader with an explicit format_name hint matching its on-disk format, exercising the named-format reader code path for each. Asserts every archive's entries and payloads round trip correctly under the explicit format_name path.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch16-multi-format-explicit-readers"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

# (write_format, read_format_hint, suffix)
plans = [
    ("gnutar", "tar", "tar"),
    ("zip", "zip", "zip"),
    ("cpio", "cpio", "cpio"),
]
expected = {
    "alpha.txt": b"alpha multi-format payload\n",
    "beta.txt": b"beta multi-format payload bytes\n",
    "gamma.bin": bytes(range(64)),
}

results = {}
for write_fmt, read_hint, suffix in plans:
    path = tmpdir / f"out.{suffix}"
    with libarchive.file_writer(str(path), write_fmt) as writer:
        for name, body in expected.items():
            writer.add_file_from_memory(name, len(body), body)

    got = {}
    with libarchive.file_reader(str(path), format_name=read_hint) as archive:
        for entry in archive:
            got[entry.pathname] = b"".join(entry.get_blocks())
    assert got == expected, (write_fmt, read_hint, sorted(got.keys()))
    results[(write_fmt, read_hint)] = len(got)

assert len(results) == len(plans), results
print("multi-format-readers", results)
PY
