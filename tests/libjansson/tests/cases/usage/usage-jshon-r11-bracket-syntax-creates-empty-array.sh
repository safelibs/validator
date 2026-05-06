#!/usr/bin/env bash
# @testcase: usage-jshon-r11-bracket-syntax-creates-empty-array
# @title: jshon -n '[]' creates an empty array literal
# @description: Asserts that jshon -n '[]' produces the empty-array sigil and that inserting it into an object yields a key whose value parses as an array of length 0.
# @timeout: 30
# @tags: usage, json, cli, build
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Standalone: -n '[]' is the empty array
got=$(printf '[]' | jshon -n '[]')
[[ "$got" == "[]" ]] || { printf 'expected [], got %s\n' "$got" >&2; exit 1; }

# Inserted into an object
result=$(printf '{}' | jshon -n '[]' -i list)
inner_type=$(printf '%s' "$result" | jshon -e list -t)
[[ "$inner_type" == "array" ]] || { printf 'expected array, got %s\n' "$inner_type" >&2; exit 1; }
inner_len=$(printf '%s' "$result" | jshon -e list -l)
[[ "$inner_len" == "0" ]] || { printf 'expected len 0, got %s\n' "$inner_len" >&2; exit 1; }
