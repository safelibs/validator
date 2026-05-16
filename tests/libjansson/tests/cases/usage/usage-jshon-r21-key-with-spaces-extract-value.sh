#!/usr/bin/env bash
# @testcase: usage-jshon-r21-key-with-spaces-extract-value
# @title: jshon extracts an object value addressed by a key containing internal spaces
# @description: Pipes a JSON object with the key "hello world" mapped to the integer 42 through jshon -e "hello world" -u and asserts the captured output equals exactly "42" - locking in libjansson's exact key matching when the key contains an internal ASCII space (existing r12 only covered the "key with spaces" extracted as a string value, not the integer-value path with an internal-space key).
# @timeout: 30
# @tags: usage, json, cli, key-spaces, extract, r21
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

got=$(printf '{"hello world":42}' | jshon -e 'hello world' -u)
[[ "$got" == "42" ]] || {
    printf 'expected 42, got %q\n' "$got" >&2
    exit 1
}
