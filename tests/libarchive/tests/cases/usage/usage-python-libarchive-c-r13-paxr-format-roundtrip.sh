#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r13-paxr-format-roundtrip
# @title: python-libarchive-c pax restricted (paxr) format writes and reads back
# @description: Writes a pax-restricted archive via file_writer format="pax_restricted" with two entries and confirms file_reader returns both pathnames and payloads in insertion order, exercising the paxr writer alongside the existing batch18 pax-restricted case.
# @timeout: 120
# @tags: usage, archive, paxr, pax
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
arc = tmpdir / "out.paxr"
entries = [
    ("first.txt", b"paxr first body\n"),
    ("second.txt", b"paxr second body bytes\n"),
]

with libarchive.file_writer(str(arc), "pax_restricted") as writer:
    for name, body in entries:
        writer.add_file_from_memory(name, len(body), body)

seen = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen.append((entry.pathname, b"".join(entry.get_blocks())))

assert seen == entries, seen
print("paxr-roundtrip", len(seen))
PY
