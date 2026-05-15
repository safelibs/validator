#!/usr/bin/env bash
# @testcase: usage-jshon-r20-continue-flag-missing-key-yields-null-type
# @title: jshon -C -e missing -t reports the type "null" for a missing key under continue mode
# @description: Pipes {"a":1} through jshon -C -e nonexistent -t and asserts the printed type is "null", exercising libjansson's value model when jshon's continue flag substitutes a null sentinel for a missing object key rather than aborting.
# @timeout: 30
# @tags: usage, json, cli, continue, missing-key, type, r20
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '{"a":1}' | jshon -C -e nonexistent -t)
[[ "$out" == "null" ]] || { printf 'expected null, got %s\n' "$out" >&2; exit 1; }
