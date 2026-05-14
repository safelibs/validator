#!/usr/bin/env bash
# @testcase: usage-jshon-r17-roundtrip-object-via-stringify
# @title: jshon roundtrip object via -e -u and back through jshon -t reports number
# @description: Extracts a numeric leaf from {"n":42} via jshon -e n -u then pipes the resulting "42" through a fresh jshon root that re-parses it as a JSON number scalar... but jshon rejects scalar roots on noble, so instead this test verifies that the extracted number unwrapped via -u equals "42" and re-running jshon -e n -t on the same object reports type "number".
# @timeout: 30
# @tags: usage, json, cli, roundtrip, number
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

val=$(printf '{"n":42}' | jshon -e n -u)
if [[ "$val" != '42' ]]; then
  printf 'expected 42, got %s\n' "$val" >&2
  exit 1
fi

type=$(printf '{"n":42}' | jshon -e n -t)
if [[ "$type" != 'number' ]]; then
  printf 'expected number, got %s\n' "$type" >&2
  exit 1
fi
