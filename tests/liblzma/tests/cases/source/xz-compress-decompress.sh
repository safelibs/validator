#!/usr/bin/env bash
# @testcase: xz-compress-decompress
# @title: xz command round trip
# @description: Compresses and decompresses text with xz command line tools.
# @timeout: 120
# @tags: cli, roundtrip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'xz payload\n' >"$tmpdir/plain"; xz -c "$tmpdir/plain" >"$tmpdir/plain.xz"; xz -dc "$tmpdir/plain.xz" >"$tmpdir/out"; cmp "$tmpdir/plain" "$tmpdir/out"; xz --list "$tmpdir/plain.xz"
