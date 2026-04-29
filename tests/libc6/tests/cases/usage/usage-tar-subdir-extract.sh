#!/usr/bin/env bash
# @testcase: usage-tar-subdir-extract
# @title: tar subdirectory extract
# @description: Exercises tar subdirectory extract through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-subdir-extract"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
printf 'tar payload\n' >"$tmpdir/in/dir/sub/value.txt"
tar -cf "$tmpdir/archive.tar" -C "$tmpdir/in" dir
tar -xf "$tmpdir/archive.tar" -C "$tmpdir/out" dir/sub/value.txt
validator_assert_contains "$tmpdir/out/dir/sub/value.txt" 'tar payload'
