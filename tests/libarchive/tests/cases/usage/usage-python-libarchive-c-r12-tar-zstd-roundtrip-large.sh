#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r12-tar-zstd-roundtrip-large
# @title: python-libarchive-c tar+zstd roundtrips a 2MB payload through file_writer
# @description: Writes a 2 MiB single-entry ustar+zstd archive and verifies file_reader iteration returns a single entry whose payload matches byte-for-byte, exercising the larger-than-typical-block payload path through the zstd write filter.
# @timeout: 240
# @tags: usage, archive, tar, zstd, large
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
arc = tmpdir / "big.tar.zst"
size = 2 * 1024 * 1024
# Deterministic, non-trivially-compressible-but-bounded payload
payload = bytes((i * 31 + 7) & 0xff for i in range(size))
src_sha = hashlib.sha256(payload).hexdigest()

with libarchive.file_writer(str(arc), "ustar", "zstd") as writer:
    writer.add_file_from_memory("big.bin", len(payload), payload)

assert arc.read_bytes()[:4] == b"\x28\xb5\x2f\xfd", arc.read_bytes()[:4].hex()

count = 0
out_sha = None
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        count += 1
        h = hashlib.sha256()
        for block in entry.get_blocks():
            h.update(block)
        out_sha = h.hexdigest()
        assert entry.pathname == "big.bin", entry.pathname
        assert entry.size == size, entry.size

assert count == 1, count
assert out_sha == src_sha, (out_sha, src_sha)
print("zstd-large", size, src_sha[:16])
PY
