#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r13-7zip-three-entries-iter-count
# @title: python-libarchive-c 7zip writer accepts three entries and iterates exactly three times
# @description: Writes three small entries into a single 7z archive via file_writer format="7zip" and asserts that file_reader iterates exactly three entries with payloads matching the original mapping.
# @timeout: 180
# @tags: usage, archive, 7zip, multi-entry
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
arc = tmpdir / "three.7z"
expected = {
    "one.txt": b"one body\n",
    "two.txt": b"second body somewhat longer\n",
    "three.bin": bytes(range(48)),
}

with libarchive.file_writer(str(arc), "7zip") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

magic = arc.read_bytes()[:6]
assert magic == b"7z\xbc\xaf\x27\x1c", magic.hex()

seen = {}
count = 0
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        count += 1
        seen[entry.pathname] = b"".join(entry.get_blocks())

assert count == 3, count
assert seen == expected, sorted(seen)
print("7zip-three", count)
PY
