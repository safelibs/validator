#!/usr/bin/env bash
# @testcase: usage-jshon-scalar-type-survey
# @title: jshon scalar type survey
# @description: Probes the -t type label for every JSON scalar and container shape and verifies each label.
# @timeout: 180
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-scalar-type-survey"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"s":"hello","n":42,"f":1.5,"bt":true,"bf":false,"nu":null,"a":[1,2],"o":{"k":"v"}}'

probe() {
  local key=$1
  local expected=$2
  printf '%s' "$json" | jshon -e "$key" -t >"$tmpdir/out"
  if ! grep -Fxq -- "$expected" "$tmpdir/out"; then
    printf 'expected type %s for key %s, got:\n' "$expected" "$key" >&2
    cat "$tmpdir/out" >&2
    exit 1
  fi
}

probe s string
probe n number
probe f number
probe bt bool
probe bf bool
probe nu null
probe a array
probe o object
