#!/usr/bin/env bash
# @testcase: usage-jshon-r11-array-extract-negative-one-last
# @title: jshon -e -1 extracts the last element of an array
# @description: Reads an array of numeric literals and asserts that jshon -e -1 -u returns the final element, exercising the documented wrap-around behavior of negative array indexes for extract.
# @timeout: 30
# @tags: usage, json, cli, negative-index
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '[10,20,30,40,50]' >"$tmpdir/in.json"
got=$(jshon -e -1 -u <"$tmpdir/in.json")
[[ "$got" == "50" ]] || { printf 'expected 50, got %s\n' "$got" >&2; exit 1; }

# Also -2 should give the second-to-last element
got2=$(jshon -e -2 -u <"$tmpdir/in.json")
[[ "$got2" == "40" ]] || { printf 'expected 40, got %s\n' "$got2" >&2; exit 1; }
