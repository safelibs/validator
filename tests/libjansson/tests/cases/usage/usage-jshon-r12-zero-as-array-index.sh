#!/usr/bin/env bash
# @testcase: usage-jshon-r12-zero-as-array-index
# @title: jshon -e 0 returns the first element of an array
# @description: Pipes a 3-element string array through jshon -e 0 -u and verifies the unstring output is the literal first string.
# @timeout: 30
# @tags: usage, json, cli, index
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

got=$(printf '["alpha","beta","gamma"]' | jshon -e 0 -u)
[[ "$got" == "alpha" ]] || { printf 'expected alpha, got %s\n' "$got" >&2; exit 1; }
