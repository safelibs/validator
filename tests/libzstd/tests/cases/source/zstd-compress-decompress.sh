#!/usr/bin/env bash
# @testcase: zstd-compress-decompress
# @title: zstd command round trip
# @description: Compresses and decompresses text through the zstd command line.
# @timeout: 120
# @tags: cli, roundtrip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'zstd payload\n' >"$tmpdir/plain"; zstd -q -c "$tmpdir/plain" >"$tmpdir/plain.zst"; zstd -q -dc "$tmpdir/plain.zst" >"$tmpdir/out"; cmp "$tmpdir/plain" "$tmpdir/out"; zstd -lv "$tmpdir/plain.zst"
