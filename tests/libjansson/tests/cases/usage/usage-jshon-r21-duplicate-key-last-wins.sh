#!/usr/bin/env bash
# @testcase: usage-jshon-r21-duplicate-key-last-wins
# @title: jshon -e on an object with duplicate keys returns the last-defined value
# @description: Pipes a JSON object literal containing two entries with the same key "a" (mapped to 1 and 3 respectively) through jshon -e a -u and asserts the captured value equals exactly "3" - locking in libjansson's documented duplicate-key resolution where the later definition supersedes the earlier one in the parsed object.
# @timeout: 30
# @tags: usage, json, cli, duplicate-key, parser, r21
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

got=$(printf '{"a":1,"b":2,"a":3}' | jshon -e a -u)
[[ "$got" == "3" ]] || {
    printf 'expected last-wins value 3, got %q\n' "$got" >&2
    exit 1
}
