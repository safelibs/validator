#!/usr/bin/env bash
# @testcase: usage-bzip2-small-mode-decompress
# @title: bzip2 -s small mode decompresses correctly
# @description: Decompresses a bzip2 stream with the low-memory -s flag and verifies bytes match the original payload.
# @timeout: 180
# @tags: usage, decompression, small-mode
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 200); do
  printf 'small-mode payload line %03d\n' "$i"
done >"$tmpdir/in.txt"

bzip2 -9 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"

# -s forces the low-memory decompression path; output must be byte-identical.
bzip2 -s -dc "$tmpdir/in.bz2" >"$tmpdir/out"
cmp "$tmpdir/in.txt" "$tmpdir/out"

orig_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')
new_sha=$(sha256sum "$tmpdir/out" | awk '{print $1}')
[[ "$orig_sha" == "$new_sha" ]]
