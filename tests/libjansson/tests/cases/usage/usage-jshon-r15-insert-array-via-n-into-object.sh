#!/usr/bin/env bash
# @testcase: usage-jshon-r15-insert-array-via-n-into-object
# @title: jshon -n array -i creates a new array-typed key on an existing object
# @description: Pre-builds a fresh empty array via -n array on the stack and chains -i items into a one-key object, then verifies the resulting object reports type "array" under the new key, has length two, and preserves the original key, exercising the documented stack-driven array insertion pattern.
# @timeout: 30
# @tags: usage, json, cli, insert
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '{"label":"things"}' | jshon -n array -i items)
len=$(printf '%s' "$result" | jshon -l)
[[ "$len" == "2" ]] || { printf 'expected length 2, got %s\n' "$len" >&2; exit 1; }
typ=$(printf '%s' "$result" | jshon -e items -t)
[[ "$typ" == "array" ]] || { printf 'expected array, got %s\n' "$typ" >&2; exit 1; }
label=$(printf '%s' "$result" | jshon -e label -u)
[[ "$label" == "things" ]] || { printf 'expected things, got %s\n' "$label" >&2; exit 1; }
