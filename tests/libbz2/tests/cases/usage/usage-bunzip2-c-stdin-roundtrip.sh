#!/usr/bin/env bash
# @testcase: usage-bunzip2-c-stdin-roundtrip
# @title: bunzip2 -c reads stdin and writes to stdout
# @description: Pipes a freshly compressed stream into bunzip2 -c on stdin and verifies stdout reproduces the original bytes exactly.
# @timeout: 180
# @tags: usage, bzip2, stream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bunzip2-c-stdin-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a deterministic payload spanning multiple bzip2 internal blocks.
python3 -c 'import sys
sys.stdout.buffer.write(b"bunzip2 -c stdin roundtrip header\n")
for i in range(5000):
    sys.stdout.buffer.write(f"row {i:05d} bunzip2 stdin payload\n".encode())
sys.stdout.buffer.write(b"bunzip2 -c stdin roundtrip footer\n")' >"$tmpdir/in.bin"

expected_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')
expected_size=$(wc -c <"$tmpdir/in.bin")

bzip2 -c "$tmpdir/in.bin" >"$tmpdir/in.bin.bz2"
bzip2 -t "$tmpdir/in.bin.bz2"

# bunzip2 -c with no positional args must read stdin and write to stdout.
bunzip2 -c <"$tmpdir/in.bin.bz2" >"$tmpdir/out.bin"

actual_sha=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
actual_size=$(wc -c <"$tmpdir/out.bin")
[[ "$actual_size" -eq "$expected_size" ]] || {
  printf 'size mismatch: expected %s got %s\n' "$expected_size" "$actual_size" >&2
  exit 1
}
[[ "$actual_sha" == "$expected_sha" ]] || {
  printf 'sha mismatch: expected %s got %s\n' "$expected_sha" "$actual_sha" >&2
  exit 1
}
cmp "$tmpdir/in.bin" "$tmpdir/out.bin"
