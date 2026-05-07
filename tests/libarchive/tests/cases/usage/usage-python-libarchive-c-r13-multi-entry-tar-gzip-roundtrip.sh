#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r13-multi-entry-tar-gzip-roundtrip
# @title: python-libarchive-c ustar+gzip roundtrips eight independent entries
# @description: Writes a tar.gz with eight entries of varying sizes through file_writer using format ustar and filter gzip, then reads back through file_reader and asserts that all eight pathnames and payloads round-trip and that the in-archive entry order matches the insertion order.
# @timeout: 120
# @tags: usage, archive, tar, gzip, multi-entry
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
arc = tmpdir / "out.tar.gz"
entries = []
for idx in range(8):
    name = f"e{idx:02d}.bin"
    body = bytes((j * (idx + 1) & 0xff) for j in range(64 + idx * 32))
    entries.append((name, body))

with libarchive.file_writer(str(arc), "ustar", "gzip") as writer:
    for name, body in entries:
        writer.add_file_from_memory(name, len(body), body)

magic = arc.read_bytes()[:2]
assert magic == b"\x1f\x8b", magic.hex()

seen = []
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        seen.append((entry.pathname, b"".join(entry.get_blocks())))

assert seen == entries, [(n, len(b)) for n, b in seen]
print("multi-entry", len(seen))
PY
