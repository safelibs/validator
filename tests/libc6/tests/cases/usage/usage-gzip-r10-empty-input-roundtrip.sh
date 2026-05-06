#!/usr/bin/env bash
# @testcase: usage-gzip-r10-empty-input-roundtrip
# @title: gzip compresses and decompresses zero-byte input losslessly
# @description: Pipes zero bytes through gzip then gunzip and verifies the decompressed stream is also zero bytes, exercising libc fread/fwrite at EOF in the gzip pipeline.
# @timeout: 60
# @tags: usage, gzip
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/in.bin"
gzip -c "$tmpdir/in.bin" >"$tmpdir/in.bin.gz"

# gzip header is at least 10 bytes even for empty payload
sz=$(wc -c <"$tmpdir/in.bin.gz")
[[ "$sz" -ge 10 ]]

gunzip -c "$tmpdir/in.bin.gz" >"$tmpdir/out.bin"
out_sz=$(wc -c <"$tmpdir/out.bin")
[[ "$out_sz" -eq 0 ]]

gzip -t "$tmpdir/in.bin.gz"
