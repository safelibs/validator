#!/usr/bin/env bash
# @testcase: usage-coreutils-tail-lines
# @title: coreutils tail line
# @description: Reads the final line of a file with tail and verifies the selected output.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-tail-lines"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'one\ntwo\nthree\n' >"$tmpdir/in.txt"
tail -n 1 "$tmpdir/in.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'three'
