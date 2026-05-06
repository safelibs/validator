#!/usr/bin/env bash
# @testcase: usage-jshon-r11-in-place-delete-key-rewrites-file
# @title: jshon -F file -I -d key rewrites the file in place
# @description: Writes a two-key object to a file, runs jshon -F path -I -d key to delete one key in place, and verifies the file now parses to an object containing only the surviving key.
# @timeout: 60
# @tags: usage, json, cli, in-place
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"keep":1,"drop":2}' >"$tmpdir/data.json"
jshon -F "$tmpdir/data.json" -I -d drop

[[ -s "$tmpdir/data.json" ]] || { printf 'file empty after in-place edit\n' >&2; exit 1; }
keys=$(jshon -F "$tmpdir/data.json" -k | sort)
expected=$'keep'
[[ "$keys" == "$expected" ]] || { printf 'expected only key "keep", got:\n%s\n' "$keys" >&2; exit 1; }
got=$(jshon -F "$tmpdir/data.json" -e keep -u)
[[ "$got" == "1" ]] || { printf 'expected 1, got %s\n' "$got" >&2; exit 1; }
