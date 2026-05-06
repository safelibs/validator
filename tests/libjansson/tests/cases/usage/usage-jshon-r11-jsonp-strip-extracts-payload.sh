#!/usr/bin/env bash
# @testcase: usage-jshon-r11-jsonp-strip-extracts-payload
# @title: jshon -P strips jsonp callback wrapper before parsing
# @description: Wraps a JSON object in a jsonp callback and verifies jshon -P unwraps it so the inner payload can be extracted via subsequent actions.
# @timeout: 60
# @tags: usage, json, cli, jsonp
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'cb({"x":42})' >"$tmpdir/in.jsonp"
got=$(jshon -P -e x -u <"$tmpdir/in.jsonp")
[[ "$got" == "42" ]] || { printf 'expected 42, got %s\n' "$got" >&2; exit 1; }
