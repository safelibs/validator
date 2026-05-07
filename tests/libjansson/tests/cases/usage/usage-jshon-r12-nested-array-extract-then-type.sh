#!/usr/bin/env bash
# @testcase: usage-jshon-r12-nested-array-extract-then-type
# @title: jshon -e a -e 1 -t reports object for nested array element
# @description: Reads an object with key "a" whose value is an array of mixed scalars and an object, and verifies jshon -e a -e 1 -t prints "object" for the second element.
# @timeout: 30
# @tags: usage, json, cli, type
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"a":["x",{"k":1},42]}' >"$tmpdir/in.json"
got=$(jshon -e a -e 1 -t <"$tmpdir/in.json")
[[ "$got" == "object" ]] || { printf 'expected object, got %s\n' "$got" >&2; exit 1; }
