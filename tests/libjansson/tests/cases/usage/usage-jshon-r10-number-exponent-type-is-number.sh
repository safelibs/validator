#!/usr/bin/env bash
# @testcase: usage-jshon-r10-number-exponent-type-is-number
# @title: jshon -t reports number for scientific-notation literal
# @description: Parses a JSON value written with exponent notation (1e3) and confirms jshon -t reports the type as "number" rather than rejecting the literal or coercing to string.
# @timeout: 60
# @tags: usage, json, cli
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"x":1e3}' | jshon -e x -t >"$tmpdir/type"
validator_assert_contains "$tmpdir/type" 'number'

printf '{"x":1e3}' | jshon -e x -u >"$tmpdir/value"
value=$(<"$tmpdir/value")
case "$value" in
  1000|1000.0|1e3|1.0e3|1e+3|1.0e+3) ;;
  *)
    printf 'unexpected stringified value for 1e3: %q\n' "$value" >&2
    exit 1
    ;;
esac
