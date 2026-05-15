#!/usr/bin/env bash
# @testcase: usage-jshon-r19-type-of-extracted-number-fractional
# @title: jshon -e k -t on a fractional number returns number
# @description: Pipes {"k":3.14} through jshon -e k -t and asserts stdout equals "number" exactly, exercising libjansson's type classification of an extracted JSON fractional number (jshon collapses int and real JSON types into the unified "number" label).
# @timeout: 30
# @tags: usage, json, cli, type, number, fractional, r19
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '{"k":3.14}' | jshon -e k -t)
if [[ "$out" != 'number' ]]; then
  printf 'expected number, got %s\n' "$out" >&2
  exit 1
fi
