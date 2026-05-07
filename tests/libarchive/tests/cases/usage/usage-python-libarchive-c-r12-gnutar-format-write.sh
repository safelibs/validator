#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r12-gnutar-format-write
# @title: python-libarchive-c file_writer produces a gnutar-format archive readable by file_reader
# @description: Writes a multi-entry archive with format="gnutar" and confirms file_reader iterates the entries with their inserted pathnames and payloads. Exercises the gnutar write format distinct from existing ustar/pax/v7tar coverage.
# @timeout: 120
# @tags: usage, archive, gnutar, format
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
arc = tmpdir / "out.gnutar"
expected = {
    "alpha.txt": b"alpha gnutar\n",
    "beta.txt": b"beta gnutar bytes\n",
    "nested/gamma.bin": bytes(range(32)),
}

with libarchive.file_writer(str(arc), "gnutar") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

seen = {}
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen[entry.pathname] = b"".join(entry.get_blocks())

assert seen == expected, (sorted(seen), sorted(expected))
print("gnutar-format", sorted(seen))
PY
