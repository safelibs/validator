#!/usr/bin/env bash
# @testcase: usage-jshon-r15-insert-object-via-n-into-object
# @title: jshon -n object -i creates a new empty-object-typed key on an existing object
# @description: Pre-builds a fresh empty object via -n object on the stack and chains -i child into a one-key object, then verifies the resulting object reports type "object" under the new key with zero internal keys and length two at the root, exercising the documented stack-driven object insertion pattern.
# @timeout: 30
# @tags: usage, json, cli, insert
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '{"label":"things"}' | jshon -n object -i child)
len=$(printf '%s' "$result" | jshon -l)
[[ "$len" == "2" ]] || { printf 'expected length 2, got %s\n' "$len" >&2; exit 1; }
typ=$(printf '%s' "$result" | jshon -e child -t)
[[ "$typ" == "object" ]] || { printf 'expected object, got %s\n' "$typ" >&2; exit 1; }
inner=$(printf '%s' "$result" | jshon -e child -l)
[[ "$inner" == "0" ]] || { printf 'expected inner length 0, got %s\n' "$inner" >&2; exit 1; }
