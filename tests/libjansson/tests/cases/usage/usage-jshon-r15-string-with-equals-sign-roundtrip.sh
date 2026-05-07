#!/usr/bin/env bash
# @testcase: usage-jshon-r15-string-with-equals-sign-roundtrip
# @title: jshon -s "key=value" -i tag preserves an equals-sign string through extract
# @description: Pre-builds a string containing an equals sign via -s "key=value" on the stack, inserts it under "tag" into a one-key object, and verifies the unstrung value extracted via -e tag -u equals the literal "key=value", exercising the documented string roundtrip.
# @timeout: 30
# @tags: usage, json, cli, insert, string
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '{"label":"things"}' | jshon -s "key=value" -i tag)
got=$(printf '%s' "$result" | jshon -e tag -u)
[[ "$got" == "key=value" ]] || { printf 'expected key=value, got %s\n' "$got" >&2; exit 1; }
typ=$(printf '%s' "$result" | jshon -e tag -t)
[[ "$typ" == "string" ]] || { printf 'expected string, got %s\n' "$typ" >&2; exit 1; }
