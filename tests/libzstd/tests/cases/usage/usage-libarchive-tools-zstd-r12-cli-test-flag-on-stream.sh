#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r12-cli-test-flag-on-stream
# @title: zstd -t accepts a frame on stdin and exits 0 for a valid stream
# @description: Pipes a freshly produced zstd frame into zstd -t via stdin, asserts the integrity check passes, and verifies that corrupting a single byte causes zstd -t to exit non-zero.
# @timeout: 60
# @tags: usage, zstd, cli, integrity
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r12 test-flag payload row\n%.0s' {1..400} >"$tmpdir/in.txt"
zstd -q "$tmpdir/in.txt" -o "$tmpdir/in.txt.zst"

# Stream-mode integrity check via stdin.
zstd -t <"$tmpdir/in.txt.zst"

# Corrupt the last byte (which falls inside the xxhash trailer or final block).
cp "$tmpdir/in.txt.zst" "$tmpdir/bad.zst"
size=$(stat -c %s "$tmpdir/bad.zst")
python3 - "$tmpdir/bad.zst" "$size" <<'PY'
import sys
path = sys.argv[1]
size = int(sys.argv[2])
with open(path, 'r+b') as fh:
    fh.seek(size - 1)
    cur = fh.read(1)
    fh.seek(size - 1)
    fh.write(bytes([cur[0] ^ 0xFF]))
PY

set +e
zstd -t "$tmpdir/bad.zst" >/dev/null 2>&1
ec=$?
set -e
[[ $ec -ne 0 ]] || {
    printf 'expected zstd -t to fail on corrupted frame\n' >&2
    exit 1
}
