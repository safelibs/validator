#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch14-targz-explicit-level-6
# @title: python-libarchive-c tar.gz explicit gzip compression-level 6
# @description: Writes a tar.gz with the gzip filter and an explicit compression-level=6 set via the file_writer options keyword (which feeds archive_write_set_options before the writer is opened, since the binding raises if options are set after open). Reads the archive back to verify the entries and payload survive the configured-level round trip and that the gzip magic header is present.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch14-targz-explicit-level-6"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

path = tmpdir / "level6.tar.gz"
expected = {
    "alpha.txt": b"alpha payload\n" * 32,
    "beta.txt": b"beta payload bytes\n" * 24,
    "gamma.bin": bytes(range(256)) * 8,
}

# options must be passed at writer construction; calling write_set_options
# after the writer has been opened raises in libarchive_c 2.9.
with libarchive.file_writer(
    str(path),
    "gnutar",
    "gzip",
    options="gzip:compression-level=6",
) as writer:
    for name, data in expected.items():
        writer.add_file_from_memory(name, len(data), data)

raw = path.read_bytes()
assert raw[:2] == b"\x1f\x8b", raw[:2]

got = {}
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == expected, sorted(got.keys())
print("targz-level-6", len(raw), len(got))
PY
