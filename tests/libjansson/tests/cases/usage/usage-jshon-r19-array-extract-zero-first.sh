#!/usr/bin/env bash
# @testcase: usage-jshon-r19-array-extract-zero-first
# @title: jshon -e 0 -u on a four-element string array yields the first element
# @description: Pipes ["alpha","beta","gamma","delta"] through jshon -e 0 -u and asserts stdout equals "alpha" exactly, exercising libjansson's zero-based positive-index semantics in jshon's -e operator with a fixture distinct from earlier negative-index r18 coverage.
# @timeout: 30
# @tags: usage, json, cli, array, zero-index, r19
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '["alpha","beta","gamma","delta"]' | jshon -e 0 -u)
if [[ "$out" != 'alpha' ]]; then
  printf 'expected alpha, got %s\n' "$out" >&2
  exit 1
fi
