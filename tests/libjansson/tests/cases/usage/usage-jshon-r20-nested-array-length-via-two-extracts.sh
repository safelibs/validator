#!/usr/bin/env bash
# @testcase: usage-jshon-r20-nested-array-length-via-two-extracts
# @title: jshon -e key -e key -l reports the length of a doubly-nested inner array
# @description: Pipes {"a":{"b":[10,20,30,40,50]}} through jshon -e a -e b -l and asserts the printed length is 5, exercising libjansson's nested container traversal via jshon's chained extract followed by length-of-array.
# @timeout: 30
# @tags: usage, json, cli, nested, extract, length, r20
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '{"a":{"b":[10,20,30,40,50]}}' | jshon -e a -e b -l)
[[ "$out" == "5" ]] || { printf 'expected length 5, got %s\n' "$out" >&2; exit 1; }
