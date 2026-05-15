#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r20-xz-empty-input-roundtrip
# @title: xz round-trips an empty payload to a zero-byte decompressed output
# @description: Compresses a zero-byte file via xz -c, asserts the resulting .xz file is non-empty (valid stream framing), then decompresses with xz -dc and asserts the decoded output is exactly zero bytes, pinning the empty-payload round-trip contract.
# @timeout: 60
# @tags: usage, xz, empty, roundtrip, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/in.bin"
xz -c "$tmpdir/in.bin" >"$tmpdir/in.xz"

s_xz=$(wc -c <"$tmpdir/in.xz")
[[ "$s_xz" -gt 0 ]] || { printf 'expected non-empty xz framing, got 0\n' >&2; exit 1; }

xz -dc "$tmpdir/in.xz" >"$tmpdir/out.bin"
s_out=$(wc -c <"$tmpdir/out.bin")
[[ "$s_out" -eq 0 ]] || { printf 'expected zero-byte decompressed, got %s\n' "$s_out" >&2; exit 1; }
