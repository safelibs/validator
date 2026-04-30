#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch13-mixed-format-detection
# @title: python-libarchive-c format auto-detection across formats
# @description: Writes the same payload set into four distinct archive containers (gnutar, ustar, pax, cpio) and verifies libarchive's auto-detection on read returns identical pathname+payload mappings for every container.
# @timeout: 240
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch13-mixed-format-detection"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

expected = {
    "alpha.txt": b"alpha\n",
    "beta/inner.txt": b"beta inner payload\n",
    "gamma.bin": bytes(range(256)),
}

formats = {
    "gnutar": tmpdir / "out.gnutar",
    "ustar": tmpdir / "out.ustar",
    "pax": tmpdir / "out.pax",
    "cpio": tmpdir / "out.cpio",
}

for fmt, path in formats.items():
    with libarchive.file_writer(str(path), fmt) as writer:
        for name, data in expected.items():
            writer.add_file_from_memory(name, len(data), data)

results = {}
for fmt, path in formats.items():
    got = {}
    with libarchive.file_reader(str(path)) as archive:
        for entry in archive:
            got[entry.pathname] = b"".join(entry.get_blocks())
    results[fmt] = got

# Every container's read-back must equal the same payload mapping.
for fmt, got in results.items():
    assert got == expected, (fmt, got)

# And all four containers must agree on the structure.
distinct = {tuple(sorted(g.items())) for g in results.values()}
assert len(distinct) == 1, results
print("mixed-formats", sorted(results.keys()))
PY
