#!/usr/bin/env bash
# @testcase: usage-bzip2-levels-1-and-9-roundtrip-1mb
# @title: bzip2 -1 and -9 round-trip a 1MB pseudo-random file
# @description: Generates a deterministic 1MB pseudo-random payload, compresses it with bzip2 -1 and bzip2 -9 separately, decompresses both, and verifies the SHA-256 of each restored byte stream matches the original.
# @timeout: 300
# @tags: usage, bzip2, compression, levels
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 1 MiB of deterministic pseudo-random bytes (covers the full byte range).
python3 -c '
import sys
size = 1024 * 1024
state = 0x1234abcd
buf = bytearray(size)
for i in range(size):
    state = (1103515245 * state + 12345) & 0x7fffffff
    buf[i] = state & 0xff
sys.stdout.buffer.write(bytes(buf))
' >"$tmpdir/in.bin"

input_size=$(wc -c <"$tmpdir/in.bin")
[[ "$input_size" -eq $((1024 * 1024)) ]] || {
  printf 'expected 1 MiB input, got %s bytes\n' "$input_size" >&2
  exit 1
}

original_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

for level in 1 9; do
  bzip2 -c "-${level}" "$tmpdir/in.bin" >"$tmpdir/in.${level}.bz2"
  validator_require_file "$tmpdir/in.${level}.bz2"

  # Compressed file must start with the canonical bzip2 magic + level byte.
  magic=$(head -c 4 "$tmpdir/in.${level}.bz2" | od -An -c | tr -d ' \n')
  expected="BZh${level}"
  [[ "$magic" == "$expected" ]] || {
    printf 'level %s: expected magic %s, got %s\n' "$level" "$expected" "$magic" >&2
    exit 1
  }

  bzip2 -dc "$tmpdir/in.${level}.bz2" >"$tmpdir/out.${level}.bin"
  roundtrip_sha=$(sha256sum "$tmpdir/out.${level}.bin" | awk '{print $1}')
  if [[ "$roundtrip_sha" != "$original_sha" ]]; then
    printf 'level %s sha mismatch: original=%s roundtrip=%s\n' \
      "$level" "$original_sha" "$roundtrip_sha" >&2
    exit 1
  fi
  cmp "$tmpdir/in.bin" "$tmpdir/out.${level}.bin"
done
