#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-r21-tar-bzip2-level-5-roundtrip
# @title: python-libarchive-c tar.bz2 with explicit bzip2 level 5 roundtrips two entries
# @description: Builds a tar.bz2 archive in memory via custom_writer with filter "bzip2" and options "bzip2:compression-level=5", writes two text entries totaling several hundred bytes, reads back via memory_reader, and asserts both pathnames and payloads are recovered intact, exercising the bzip2 compression-level=5 filter option distinct from prior explicit level 1 (r19) and level 9 (r20) cases.
# @timeout: 120
# @tags: usage, archive, tar, bzip2, level-5, r21
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import io
import libarchive

entries = [
    ("alpha.txt", b"r21 bzip2 level 5 alpha payload " * 4),
    ("beta.txt",  b"r21 bzip2 level 5 beta payload " * 4),
]
buf = io.BytesIO()
def cb(chunk):
    buf.write(bytes(chunk))
    return len(chunk)

with libarchive.custom_writer(cb, "ustar", filter_name="bzip2", options="bzip2:compression-level=5") as writer:
    for n, p in entries:
        writer.add_file_from_memory(n, len(p), p)

raw = buf.getvalue()
assert len(raw) > 0
got = []
with libarchive.memory_reader(raw) as archive:
    for entry in archive:
        chunks = b"".join(bytes(b) for b in entry.get_blocks())
        got.append((entry.pathname, chunks))

assert got == entries, got
print("bzip2-level5-ok", [n for n, _ in got])
PY
