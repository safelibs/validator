#!/usr/bin/env bash
# @testcase: usage-jshon-r15-delete-three-keys-leaves-one
# @title: jshon chains three -d deletes and reports length one with the remaining key
# @description: Pipes a 4-key object through three chained -d deletes and verifies the resulting object reports length one and the surviving key when listed via -k, exercising the documented chained deletion behaviour.
# @timeout: 30
# @tags: usage, json, cli, delete
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '{"a":1,"b":2,"c":3,"d":4}' | jshon -d a -d b -d c)
len=$(printf '%s' "$result" | jshon -l)
[[ "$len" == "1" ]] || { printf 'expected length 1, got %s\n' "$len" >&2; exit 1; }
printf '%s' "$result" | jshon -k >"$tmpdir/keys"
diff -u <(printf 'd\n') "$tmpdir/keys"
