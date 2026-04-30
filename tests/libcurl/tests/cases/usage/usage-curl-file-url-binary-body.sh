#!/usr/bin/env bash
# @testcase: usage-curl-file-url-binary-body
# @title: curl file:// URL preserves binary bytes
# @description: Reads a binary file via a file:// URL with curl and confirms the downloaded copy is byte-for-byte identical to the source through cmp.
# @timeout: 120
# @tags: usage, curl, file
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-file-url-binary-body"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 512 bytes of all distinct byte values across two passes.
python3 -c '
import sys
data = bytes(range(256)) + bytes(range(255, -1, -1))
open(sys.argv[1], "wb").write(data)
' "$tmpdir/source.bin"

curl -fsS -o "$tmpdir/copy.bin" "file://$tmpdir/source.bin"
cmp "$tmpdir/source.bin" "$tmpdir/copy.bin"

size=$(stat -c '%s' "$tmpdir/copy.bin")
if [[ "$size" -ne 512 ]]; then
  printf 'expected 512 bytes, got %s\n' "$size" >&2
  exit 1
fi
