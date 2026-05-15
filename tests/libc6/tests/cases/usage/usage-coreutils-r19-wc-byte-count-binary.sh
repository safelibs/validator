#!/usr/bin/env bash
# @testcase: usage-coreutils-r19-wc-byte-count-binary
# @title: wc -c reports the exact byte count of a 1024-byte binary file
# @description: Generates a 1024-byte binary file with python and runs wc -c against it, then asserts the leading numeric token is exactly 1024 - locking in libc-backed file-size accounting through coreutils wc.
# @timeout: 30
# @tags: usage, coreutils, wc, bytes, r19
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/blob.bin" <<'PY'
import sys
with open(sys.argv[1], 'wb') as f:
    f.write(bytes(i % 256 for i in range(1024)))
PY

n=$(wc -c <"$tmpdir/blob.bin")
[[ "$n" -eq 1024 ]] || {
    printf 'expected 1024, got %s\n' "$n" >&2
    exit 1
}
