#!/usr/bin/env bash
# @testcase: usage-jshon-r14-roundtrip-deeply-nested-three-levels
# @title: jshon parses and reprints a 3-level nested object preserving the leaf
# @description: Pipes a 3-level nested object through jshon (no transforms) and verifies the resulting output, when re-parsed, still extracts the same leaf value via jshon -e a -e b -e c -u, exercising idempotent reprinting through three levels.
# @timeout: 30
# @tags: usage, json, cli, roundtrip
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"a":{"b":{"c":"hello"}}}' | jshon >"$tmpdir/round.json"
got=$(jshon -e a -e b -e c -u <"$tmpdir/round.json")
[[ "$got" == "hello" ]] || { printf 'expected hello, got %s\n' "$got" >&2; exit 1; }
