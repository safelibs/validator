#!/usr/bin/env bash
# @testcase: usage-bash-mapfile-array
# @title: bash mapfile reads file into array
# @description: Uses mapfile -t to load lines from a file into an array and verifies element count and content.
# @timeout: 120
# @tags: usage, bash
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-mapfile-array"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\ngamma\ndelta\n' >"$tmpdir/lines.txt"
mapfile -t arr <"$tmpdir/lines.txt"
test "${#arr[@]}" -eq 4
test "${arr[0]}" = 'alpha'
test "${arr[1]}" = 'beta'
test "${arr[2]}" = 'gamma'
test "${arr[3]}" = 'delta'
