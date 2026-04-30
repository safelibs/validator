#!/usr/bin/env bash
# @testcase: usage-bzip2-decompress-bz-suffix
# @title: bzip2 -d strips the .bz suffix
# @description: Verifies that bzip2 -d recognises the legacy .bz extension and decompresses payload.bz to a suffix-less payload file with the original bytes.
# @timeout: 180
# @tags: usage, bzip2, suffix
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-decompress-bz-suffix"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a deterministic payload and capture its checksum for cmp.
python3 -c "import sys
for i in range(64):
    sys.stdout.write(f'bz suffix payload line {i}\n')" >"$tmpdir/payload.txt"

# Compress to stdout, then drop the result under a .bz (not .bz2) name.
bzip2 -c "$tmpdir/payload.txt" >"$tmpdir/payload.bz"
validator_require_file "$tmpdir/payload.bz"

# In-place decompression must accept the .bz suffix and produce the suffix-less file.
bzip2 -d "$tmpdir/payload.bz"
[[ ! -e "$tmpdir/payload.bz" ]] || {
  printf 'bzip2 -d left the .bz file in place\n' >&2
  exit 1
}
validator_require_file "$tmpdir/payload"
cmp "$tmpdir/payload.txt" "$tmpdir/payload"
