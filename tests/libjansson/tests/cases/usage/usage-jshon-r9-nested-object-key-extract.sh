#!/usr/bin/env bash
# @testcase: usage-jshon-r9-nested-object-key-extract
# @title: jshon nested object key extract
# @description: Extracts a string value from a three-level nested object using chained -e and -u and verifies the leaf string is rendered verbatim.
# @timeout: 60
# @tags: usage, json, nested
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"top":{"middle":{"leaf":"hello-deep"}}}'

printf '%s' "$json" | jshon -e top -e middle -e leaf -u >"$tmpdir/out"
got=$(cat "$tmpdir/out")
[[ "$got" == "hello-deep" ]] || {
  printf 'expected hello-deep, got %s\n' "$got" >&2
  exit 1
}
