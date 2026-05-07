#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r14-zip-then-tar-of-zip
# @title: python-libarchive-c packages a zip archive inside a tar.gz outer archive
# @description: Builds an inner zip archive via file_writer, then wraps it as a single entry in an outer ustar+gzip archive, reads the outer archive back, extracts the inner zip bytes from the entry payload, and verifies they roundtrip-decode through libarchive.memory_reader to the original three entries.
# @timeout: 120
# @tags: usage, archive, zip, tar, gzip, nested
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
inner = tmpdir / "inner.zip"
outer = tmpdir / "outer.tar.gz"
inner_entries = {
    "alpha.txt": b"nested alpha\n",
    "beta.txt": b"nested beta payload bytes\n",
    "gamma.bin": bytes(range(48)),
}

with libarchive.file_writer(str(inner), "zip") as writer:
    for name, body in inner_entries.items():
        writer.add_file_from_memory(name, len(body), body)

inner_bytes = inner.read_bytes()
assert inner_bytes[:2] == b"PK", inner_bytes[:2]

with libarchive.file_writer(str(outer), "ustar", "gzip") as writer:
    writer.add_file_from_memory("inner.zip", len(inner_bytes), inner_bytes)

# Read outer; extract inner payload.
extracted = None
with libarchive.file_reader(str(outer)) as archive:
    for entry in archive:
        assert entry.pathname == "inner.zip", entry.pathname
        extracted = b"".join(entry.get_blocks())

assert extracted == inner_bytes, (len(extracted) if extracted else None, len(inner_bytes))

# Re-decode the recovered zip bytes via memory_reader.
seen = {}
with libarchive.memory_reader(extracted) as archive:
    for entry in archive:
        seen[entry.pathname] = b"".join(entry.get_blocks())

assert seen == inner_entries, sorted(seen)
print("nested-zip-in-tar", len(seen), len(inner_bytes))
PY
