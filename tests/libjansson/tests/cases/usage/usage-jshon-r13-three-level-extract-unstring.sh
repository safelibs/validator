#!/usr/bin/env bash
# @testcase: usage-jshon-r13-three-level-extract-unstring
# @title: jshon -e a -e b -e c -u walks three nested objects to a leaf string
# @description: Reads a JSON object nested three levels deep with a string leaf and verifies jshon -e a -e b -e c -u prints exactly the leaf payload, exercising chained extract through three object levels.
# @timeout: 30
# @tags: usage, json, cli, extract
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"a":{"b":{"c":"deep"}}}' >"$tmpdir/in.json"
got=$(jshon -e a -e b -e c -u <"$tmpdir/in.json")
[[ "$got" == "deep" ]] || { printf 'expected deep, got %s\n' "$got" >&2; exit 1; }
