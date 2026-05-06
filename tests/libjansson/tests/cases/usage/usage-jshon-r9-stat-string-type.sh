#!/usr/bin/env bash
# @testcase: usage-jshon-r9-stat-string-type
# @title: jshon -t reports string type
# @description: Extracts a string field and runs -t to verify jshon reports the type literally as 'string'.
# @timeout: 60
# @tags: usage, json, type
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"label":"hello","count":42,"flag":true}'

printf '%s' "$json" | jshon -e label -t >"$tmpdir/t1"
got=$(cat "$tmpdir/t1")
[[ "$got" == "string" ]] || { printf 'expected string, got %s\n' "$got" >&2; exit 1; }

printf '%s' "$json" | jshon -e count -t >"$tmpdir/t2"
got=$(cat "$tmpdir/t2")
[[ "$got" == "number" ]] || { printf 'expected number, got %s\n' "$got" >&2; exit 1; }

printf '%s' "$json" | jshon -e flag -t >"$tmpdir/t3"
got=$(cat "$tmpdir/t3")
[[ "$got" == "bool" ]] || { printf 'expected bool, got %s\n' "$got" >&2; exit 1; }
