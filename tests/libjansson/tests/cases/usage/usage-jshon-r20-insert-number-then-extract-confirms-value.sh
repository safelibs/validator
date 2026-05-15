#!/usr/bin/env bash
# @testcase: usage-jshon-r20-insert-number-then-extract-confirms-value
# @title: jshon -n value -i key then -e key -u returns the inserted number as a string
# @description: Starts with the object {"a":1}, creates a JSON number 42 via -n, inserts it at key "b", then re-extracts -e b -u and asserts the result is "42", exercising libjansson's number value round-trip through jshon's nonstring/insert/extract chain.
# @timeout: 30
# @tags: usage, json, cli, object, insert, number, r20
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '{"a":1}' | jshon -n 42 -i b -e b -u)
[[ "$out" == "42" ]] || { printf 'expected 42, got %s\n' "$out" >&2; exit 1; }
