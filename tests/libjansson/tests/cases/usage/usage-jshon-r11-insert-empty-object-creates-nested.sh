#!/usr/bin/env bash
# @testcase: usage-jshon-r11-insert-empty-object-creates-nested
# @title: jshon -n object -i key creates an empty nested object
# @description: Starting from {}, uses -n object -i nested to add a key whose value is the empty object; verifies the parent has length 1 and the nested value parses as an object of length 0.
# @timeout: 30
# @tags: usage, json, cli, build
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{}' >"$tmpdir/in.json"
result=$(jshon -n object -i nested <"$tmpdir/in.json")

parent_len=$(printf '%s' "$result" | jshon -l)
[[ "$parent_len" == "1" ]] || { printf 'expected parent len 1, got %s\n' "$parent_len" >&2; exit 1; }

inner_type=$(printf '%s' "$result" | jshon -e nested -t)
[[ "$inner_type" == "object" ]] || { printf 'expected object, got %s\n' "$inner_type" >&2; exit 1; }
inner_len=$(printf '%s' "$result" | jshon -e nested -l)
[[ "$inner_len" == "0" ]] || { printf 'expected inner len 0, got %s\n' "$inner_len" >&2; exit 1; }
