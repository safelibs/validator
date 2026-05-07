#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r15-tar-zip-roundtrip-format-detection
# @title: python-libarchive-c file_reader auto-detects format on tar+gzip and zip independently
# @description: Builds two archives over the same payload set: a tar.gz via file_writer("gnutar","gzip") and a zip via file_writer(format_name="zip", filter_name=None) (the zip format takes no separate filter on libarchive_c 2.9). Reads each back through file_reader without supplying a format hint and asserts the auto-detection path returns identical (pathname, payload) maps. Confirms the binding's no-format-hint reader handles both layouts in one test, distinct from existing single-format readback cases.
# @timeout: 180
# @tags: usage, archive, format-detection, tar, zip
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
expected = {
    "alpha.txt": b"r15 format-detect alpha\n",
    "nested/beta.bin": bytes(range(80)),
    "gamma.log": b"r15 format-detect gamma\nsecond line\n",
}

targz = tmpdir / "out.tar.gz"
zipf = tmpdir / "out.zip"

with libarchive.file_writer(str(targz), "gnutar", "gzip") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

# zip format: no separate filter (libarchive's zip writer ignores filter args).
with libarchive.file_writer(str(zipf), format_name="zip", filter_name=None) as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

# Magic-byte sanity checks.
assert targz.read_bytes()[:2] == b"\x1f\x8b", targz.read_bytes()[:2]
assert zipf.read_bytes()[:4] == b"PK\x03\x04", zipf.read_bytes()[:4]

def read(path):
    out = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            out[entry.pathname] = b"".join(entry.get_blocks())
    return out

targz_got = read(targz)
zip_got = read(zipf)

assert targz_got == expected, sorted(targz_got)
assert zip_got == expected, sorted(zip_got)
assert targz_got == zip_got, "auto-detect produced divergent payloads"
print("format-detect", len(targz_got))
PY
