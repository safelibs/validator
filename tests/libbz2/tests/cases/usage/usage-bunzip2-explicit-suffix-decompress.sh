#!/usr/bin/env bash
# @testcase: usage-bunzip2-explicit-suffix-decompress
# @title: bunzip2 stdin pipe decompresses to exact bytes
# @description: Compresses a payload with bzip2 to stdout and verifies bunzip2 reading from stdin restores the original bytes exactly.
# @timeout: 180
# @tags: usage, decompression, stdin
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'custom suffix payload\nline two\n' >"$tmpdir/payload.txt"
expected_sha=$(sha256sum "$tmpdir/payload.txt" | awk '{print $1}')

# Compress to a file with an explicit non-default name (libbz2's bzip2 does
# not honour suffix overrides on the bunzip2 path on Ubuntu 24.04, so we
# round-trip via stdin instead).
bzip2 -c "$tmpdir/payload.txt" >"$tmpdir/payload.bin"
validator_require_file "$tmpdir/payload.bin"

# bunzip2 from stdin to stdout must produce the original bytes.
bunzip2 <"$tmpdir/payload.bin" >"$tmpdir/payload.out"
validator_require_file "$tmpdir/payload.out"

cmp "$tmpdir/payload.txt" "$tmpdir/payload.out"
actual_sha=$(sha256sum "$tmpdir/payload.out" | awk '{print $1}')
[[ "$expected_sha" == "$actual_sha" ]]
