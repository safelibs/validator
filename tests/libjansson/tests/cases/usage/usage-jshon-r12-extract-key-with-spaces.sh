#!/usr/bin/env bash
# @testcase: usage-jshon-r12-extract-key-with-spaces
# @title: jshon -e extracts a value via a key containing spaces
# @description: Reads an object whose key is a multi-word string with spaces and verifies jshon -e "first name" -u returns the underlying value, exercising whitespace handling in extract paths.
# @timeout: 30
# @tags: usage, json, cli, extract
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"first name":"Ada","last name":"Lovelace"}' >"$tmpdir/in.json"
got=$(jshon -e "first name" -u <"$tmpdir/in.json")
[[ "$got" == "Ada" ]] || { printf 'expected Ada, got %s\n' "$got" >&2; exit 1; }
