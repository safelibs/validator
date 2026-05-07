#!/usr/bin/env bash
# @testcase: usage-jshon-r14-string-with-unicode-snowman-roundtrip
# @title: jshon -s with a UTF-8 snowman roundtrips intact through -e -u
# @description: Builds an object with a single value containing the UTF-8 snowman character via jshon -s value -i icon, then extracts it back with -e icon -u and verifies the recovered byte sequence equals the original UTF-8 encoding.
# @timeout: 30
# @tags: usage, json, cli, unicode
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

snowman=$'\xe2\x98\x83'
printf '{}' | jshon -s "$snowman" -i icon >"$tmpdir/built.json"
got=$(jshon -e icon -u <"$tmpdir/built.json")
[[ "$got" == "$snowman" ]] || { printf 'snowman mismatch: got %s\n' "$got" >&2; exit 1; }
