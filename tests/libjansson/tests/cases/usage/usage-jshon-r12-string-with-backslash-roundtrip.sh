#!/usr/bin/env bash
# @testcase: usage-jshon-r12-string-with-backslash-roundtrip
# @title: jshon -u decodes JSON escaped backslash to single backslash
# @description: Reads a string value containing a JSON-escaped backslash and verifies jshon -u outputs the literal single backslash character.
# @timeout: 30
# @tags: usage, json, cli, escape
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"path":"a\\\\b"}' >"$tmpdir/in.json"
got=$(jshon -e path -u <"$tmpdir/in.json")
[[ "$got" == 'a\b' ]] || { printf 'expected a\\b, got %s\n' "$got" >&2; exit 1; }
