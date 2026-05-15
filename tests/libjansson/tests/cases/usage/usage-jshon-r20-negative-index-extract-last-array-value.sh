#!/usr/bin/env bash
# @testcase: usage-jshon-r20-negative-index-extract-last-array-value
# @title: jshon -e -1 -u returns the last array element's unstrung value
# @description: Pipes ["alpha","beta","gamma"] through jshon -e -1 -u and asserts the result is "gamma", exercising libjansson's array wraparound indexing via jshon's negative-index extraction.
# @timeout: 30
# @tags: usage, json, cli, array, negative-index, extract, r20
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '["alpha","beta","gamma"]' | jshon -e -1 -u)
[[ "$out" == "gamma" ]] || { printf 'expected gamma, got %s\n' "$out" >&2; exit 1; }
