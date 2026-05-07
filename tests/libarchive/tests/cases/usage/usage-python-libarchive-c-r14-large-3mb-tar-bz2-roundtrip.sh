#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r14-large-3mb-tar-bz2-roundtrip
# @title: python-libarchive-c roundtrips a 3MB single-entry tar.bz2 archive
# @description: Builds a deterministic 3 MiB payload, writes it as a single ustar+bzip2 archive via file_writer, and asserts the read-back entry has the expected size and sha256, exercising the bzip2 write filter on a payload above 2 MiB.
# @timeout: 240
# @tags: usage, archive, tar, bzip2, large
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import hashlib
import sys
from pathlib import Path
import libarchive

tmpdir = Path(sys.argv[1])
arc = tmpdir / "big.tar.bz2"
size = 3 * 1024 * 1024
payload = bytes((i * 17 + 5) & 0xff for i in range(size))
src_sha = hashlib.sha256(payload).hexdigest()

with libarchive.file_writer(str(arc), "ustar", "bzip2") as writer:
    writer.add_file_from_memory("big.bin", len(payload), payload)

# bzip2 magic 'BZh'
raw_head = arc.read_bytes()[:3]
assert raw_head == b"BZh", raw_head.hex()

count = 0
out_sha = None
out_size = None
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        count += 1
        h = hashlib.sha256()
        for block in entry.get_blocks():
            h.update(block)
        out_sha = h.hexdigest()
        out_size = entry.size
        assert entry.pathname == "big.bin", entry.pathname

assert count == 1, count
assert out_size == size, out_size
assert out_sha == src_sha, (out_sha, src_sha)
print("tar-bz2-large", size, src_sha[:16])
PY
