#!/usr/bin/env bash
# @testcase: usage-jshon-r12-empty-string-value-unstring
# @title: jshon -e key -u prints empty string for a JSON empty-string value
# @description: Reads an object with a key whose value is the empty string and verifies jshon -e key -u outputs zero bytes while -e key -t reports the type as string.
# @timeout: 30
# @tags: usage, json, cli, string
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"k":""}' >"$tmpdir/in.json"
val=$(jshon -e k -u <"$tmpdir/in.json")
[[ -z "$val" ]] || { printf 'expected empty, got %s\n' "$val" >&2; exit 1; }
typ=$(jshon -e k -t <"$tmpdir/in.json")
[[ "$typ" == "string" ]] || { printf 'expected string, got %s\n' "$typ" >&2; exit 1; }
