#!/usr/bin/env bash
# @testcase: usage-jshon-r14-insert-bool-true-into-object
# @title: jshon -n true -i flag adds a boolean-true value under a new key
# @description: Starts from an empty object and chains -n true -i flag through jshon to add a boolean-true value under the key "flag", then verifies the resulting -e flag -t reports "bool" and -e flag -u prints the literal "true".
# @timeout: 30
# @tags: usage, json, cli, insert
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '{}' | jshon -n true -i flag)
typ=$(printf '%s' "$result" | jshon -e flag -t)
[[ "$typ" == "bool" ]] || { printf 'expected bool, got %s\n' "$typ" >&2; exit 1; }
val=$(printf '%s' "$result" | jshon -e flag -u)
[[ "$val" == "true" ]] || { printf 'expected true, got %s\n' "$val" >&2; exit 1; }
