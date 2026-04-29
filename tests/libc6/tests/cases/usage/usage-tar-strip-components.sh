#!/usr/bin/env bash
# @testcase: usage-tar-strip-components
# @title: tar strip components
# @description: Extracts a tar archive with stripped leading path segments and verifies the flattened output file.
# @timeout: 180
# @tags: usage, tar, archive
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-strip-components"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/top/inner" "$tmpdir/out"
printf 'strip payload\n' >"$tmpdir/in/top/inner/file.txt"
tar -cf "$tmpdir/archive.tar" -C "$tmpdir/in" top
tar -xf "$tmpdir/archive.tar" --strip-components=2 -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/file.txt" 'strip payload'
