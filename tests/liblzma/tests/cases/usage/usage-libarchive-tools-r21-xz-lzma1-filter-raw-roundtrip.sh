#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r21-xz-lzma1-filter-raw-roundtrip
# @title: xz --format=raw --lzma1 raw filter chain round-trips a small payload
# @description: Compresses a payload using xz --format=raw --lzma1=preset=6, decompresses with the same raw filter chain, and asserts the SHA of the recovered bytes matches the original, pinning the raw-format custom-filter encode/decode path in the liblzma CLI.
# @timeout: 60
# @tags: usage, xz, raw, lzma1, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'raw-lzma1-filter-chain-payload-%s\n' alpha beta gamma >"$tmpdir/in.txt"
sha_in=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz --format=raw --lzma1=preset=6 -c "$tmpdir/in.txt" >"$tmpdir/raw.bin"
validator_require_file "$tmpdir/raw.bin"

xz -d --format=raw --lzma1=preset=6 -c "$tmpdir/raw.bin" >"$tmpdir/out.txt"
sha_out=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
[[ "$sha_in" == "$sha_out" ]] || { echo "sha mismatch in=$sha_in out=$sha_out" >&2; exit 1; }
