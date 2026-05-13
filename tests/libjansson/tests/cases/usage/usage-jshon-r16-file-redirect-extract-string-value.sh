#!/usr/bin/env bash
# @testcase: usage-jshon-r16-file-redirect-extract-string-value
# @title: jshon reads JSON from stdin redirect and extracts a string value via -e -u
# @description: Writes a small JSON object to a temporary file, redirects it to jshon -e name -u, and asserts stdout equals "r16-fixture" exactly, exercising libjansson's file-redirect parse path through the documented -e/-u extraction chain.
# @timeout: 30
# @tags: usage, json, cli, stdin-redirect
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.json" <<'JSON'
{"name":"r16-fixture","count":3}
JSON

out=$(jshon -e name -u <"$tmpdir/in.json")
[[ "$out" == "r16-fixture" ]] || {
  printf 'expected r16-fixture, got %s\n' "$out" >&2
  exit 1
}
