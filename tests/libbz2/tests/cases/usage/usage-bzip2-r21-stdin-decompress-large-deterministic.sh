#!/usr/bin/env bash
# @testcase: usage-bzip2-r21-stdin-decompress-large-deterministic
# @title: bzip2 stdin->stdout roundtrip preserves a 512KB deterministic payload
# @description: Generates a 512KB deterministic payload using printf and seq, pipes it through bzip2 -c | bzip2 -dc and asserts the SHA-256 of the recovered stream matches the source - locking in a larger-than-typical pipe-roundtrip distinct from prior 1MB random or tiny tests by using a deterministic payload of a different size.
# @timeout: 60
# @tags: usage, bzip2, stdin-stdout, sha256, r21
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Deterministic payload: 512KB built by concatenating a 1024-byte block 512 times.
block=$(printf 'abcdefghijklmnop%.0s' {1..64})  # 16 * 64 = 1024 bytes
: >"$tmpdir/orig.bin"
for _ in $(seq 1 512); do
    printf '%s' "$block" >>"$tmpdir/orig.bin"
done
src_sha=$(sha256sum "$tmpdir/orig.bin" | awk '{print $1}')

bzip2 -c <"$tmpdir/orig.bin" | bzip2 -dc >"$tmpdir/out.bin"
out_sha=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')

[[ "$out_sha" == "$src_sha" ]] || {
    printf 'sha256 mismatch: src=%s out=%s\n' "$src_sha" "$out_sha" >&2
    exit 1
}
n=$(wc -c <"$tmpdir/out.bin")
[[ "$n" -eq 524288 ]] || { printf 'expected 524288 bytes, got %s\n' "$n" >&2; exit 1; }
