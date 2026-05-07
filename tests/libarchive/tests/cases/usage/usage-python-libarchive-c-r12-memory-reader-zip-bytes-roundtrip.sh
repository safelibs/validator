#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r12-memory-reader-zip-bytes-roundtrip
# @title: python-libarchive-c memory_reader on bytes object iterates a zip archive
# @description: Builds a zip archive with file_writer, slurps the bytes off disk, and feeds them to libarchive.memory_reader to confirm the entries surface with their original names and payloads via in-memory iteration.
# @timeout: 120
# @tags: usage, archive, zip, memory-reader
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
arc = tmpdir / "in.zip"
expected = {
    "alpha.txt": b"alpha bytes\n",
    "beta.txt": b"beta-bytes-payload\n",
    "gamma.bin": bytes(range(64)),
}

with libarchive.file_writer(str(arc), "zip") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

raw = arc.read_bytes()
assert raw[:2] == b"PK", raw[:2]

seen = {}
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        seen[entry.pathname] = b"".join(entry.get_blocks())

assert seen == expected, (sorted(seen), sorted(expected))
print("memory-reader-zip", len(seen), len(raw))
PY
