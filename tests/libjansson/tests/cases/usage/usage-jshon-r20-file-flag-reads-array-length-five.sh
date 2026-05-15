#!/usr/bin/env bash
# @testcase: usage-jshon-r20-file-flag-reads-array-length-five
# @title: jshon -F path -l reports the five-element array length when reading from a file
# @description: Writes [1,2,3,4,5] to a tempfile, runs jshon -F <path> -l, and asserts the printed length is 5, exercising libjansson's file-based JSON load path through jshon's -F non-manipulation flag with stdin closed.
# @timeout: 30
# @tags: usage, json, cli, file, length, r20
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '[1,2,3,4,5]' >"$tmpdir/in.json"
out=$(jshon -F "$tmpdir/in.json" -l </dev/null)
[[ "$out" == "5" ]] || { printf 'expected length 5, got %s\n' "$out" >&2; exit 1; }
