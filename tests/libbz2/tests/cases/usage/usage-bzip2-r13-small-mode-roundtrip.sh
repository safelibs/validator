#!/usr/bin/env bash
# @testcase: usage-bzip2-r13-small-mode-roundtrip
# @title: bzip2 -s small-memory decompress roundtrips a payload
# @description: Compresses a payload with default settings, then decodes it with "bzip2 -s -dc" (small-memory mode) and verifies the decoded stdout matches the source byte-for-byte via sha256.
# @timeout: 60
# @tags: usage, bzip2, small-mode
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 200); do
    printf 'small-mode row %03d alpha beta\n' "$i"
done >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 -c "$tmpdir/in.txt" >"$tmpdir/out.bz2"

bzip2 -s -dc "$tmpdir/out.bz2" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
