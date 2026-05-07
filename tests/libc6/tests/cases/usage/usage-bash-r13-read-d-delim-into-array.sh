#!/usr/bin/env bash
# @testcase: usage-bash-r13-read-d-delim-into-array
# @title: bash read -d '' loads NUL-delimited records via libc read
# @description: Builds a NUL-delimited stream of three records, uses bash read -d '' in a while loop to consume them via libc read into an array, and asserts the array length and contents are exact.
# @timeout: 60
# @tags: usage, bash, read, libc
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\0beta\0gamma\0' >"$tmpdir/in.bin"

declare -a items=()
while IFS= read -r -d '' rec; do
  items+=("$rec")
done <"$tmpdir/in.bin"

[[ "${#items[@]}" -eq 3 ]]
[[ "${items[0]}" == "alpha" ]]
[[ "${items[1]}" == "beta" ]]
[[ "${items[2]}" == "gamma" ]]
