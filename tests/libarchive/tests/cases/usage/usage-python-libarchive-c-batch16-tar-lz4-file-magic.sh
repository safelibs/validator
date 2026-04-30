#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch16-tar-lz4-file-magic
# @title: python-libarchive-c tar.lz4 file magic identification
# @description: Writes a gnutar archive through the lz4 filter via python-libarchive-c, asserts the lz4 frame magic on disk, runs the file(1) command and confirms it identifies the payload as LZ4 compressed data, then reads the archive back and verifies the entries.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch16-tar-lz4-file-magic"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

archive_path="$tmpdir/out.tar.lz4"

python3 - <<'PY' "$case_id" "$tmpdir" "$archive_path"
from pathlib import Path
import sys
import libarchive

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
archive_path = Path(sys.argv[3])

expected = {
    "alpha.txt": b"alpha lz4 payload\n" * 32,
    "beta.txt": b"beta lz4 payload bytes\n" * 24,
}
with libarchive.file_writer(str(archive_path), "gnutar", "lz4") as writer:
    for name, body in expected.items():
        writer.add_file_from_memory(name, len(body), body)

# lz4 frame magic 0x184D2204 (little endian).
head = archive_path.read_bytes()[:4]
assert head == b"\x04\x22\x4d\x18", head

got = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        got[entry.pathname] = b"".join(entry.get_blocks())
assert got == expected, sorted(got.keys())
print("tar-lz4", len(got))
PY

# file(1) recognises the lz4 frame magic and reports either "LZ4 compressed
# data" (newer file) or at minimum mentions LZ4. Accept either phrasing.
file_out=$(file -b "$archive_path")
case "$file_out" in
  *LZ4*|*lz4*) ;;
  *)
    printf 'unexpected file(1) output: %s\n' "$file_out" >&2
    exit 1
    ;;
esac
printf 'file(1): %s\n' "$file_out"
