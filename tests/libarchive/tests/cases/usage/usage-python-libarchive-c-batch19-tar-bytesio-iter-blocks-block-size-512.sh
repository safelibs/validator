#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch19-tar-bytesio-iter-blocks-block-size-512
# @title: python-libarchive-c tar entry get_blocks(block_size=512) reads payload
# @description: Writes a tar archive with a 4096-byte payload and reads it back via entry.get_blocks(block_size=512), verifying the concatenated bytes equal the original.
# @timeout: 120
# @tags: usage, archive, tar
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
arc = tmpdir / "blocks.tar"
payload = bytes(range(256)) * 16  # 4096 bytes
with libarchive.file_writer(str(arc), "gnutar") as writer:
    writer.add_file_from_memory("payload.bin", len(payload), payload)

got = b""
n_blocks = 0
with libarchive.file_reader(str(arc)) as archive:
    for entry in archive:
        for block in entry.get_blocks(block_size=512):
            got += block
            n_blocks += 1

print("len", len(got))
print("blocks", n_blocks)
assert got == payload
assert n_blocks >= 1
PY
