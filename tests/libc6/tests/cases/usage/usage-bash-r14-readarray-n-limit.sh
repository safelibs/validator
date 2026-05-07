#!/usr/bin/env bash
# @testcase: usage-bash-r14-readarray-n-limit
# @title: bash readarray -n N reads at most N lines from a longer input
# @description: Writes a six-line input file, runs readarray -t -n 3 to load only the first three lines into an array via libc-backed read, asserts the array has exactly three elements with the expected values, and asserts the file still has six lines on disk to confirm only the array was bounded.
# @timeout: 60
# @tags: usage, bash, readarray, libc
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'one\ntwo\nthree\nfour\nfive\nsix\n' >"$tmpdir/in.txt"

declare -a arr=()
readarray -t -n 3 arr <"$tmpdir/in.txt"

[[ "${#arr[@]}" -eq 3 ]]
[[ "${arr[0]}" == "one" ]]
[[ "${arr[1]}" == "two" ]]
[[ "${arr[2]}" == "three" ]]

# Source file untouched: still six lines.
total=$(wc -l <"$tmpdir/in.txt")
[[ "$total" -eq 6 ]]
