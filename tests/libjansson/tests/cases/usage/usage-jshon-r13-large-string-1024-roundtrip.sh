#!/usr/bin/env bash
# @testcase: usage-jshon-r13-large-string-1024-roundtrip
# @title: jshon -s a 1024-character string and -e -u recovers it intact
# @description: Builds an object with a single 1024-character ASCII string value via jshon -s value -i blob, then extracts it back with -e blob -u and verifies the recovered byte sequence matches the original byte-for-byte.
# @timeout: 60
# @tags: usage, json, cli, scale
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

big=$(printf 'x%.0s' $(seq 1 1024))
printf '{}' | jshon -s "$big" -i blob >"$tmpdir/built.json"
got=$(jshon -e blob -u <"$tmpdir/built.json")
[[ "${#got}" == 1024 ]] || { printf 'expected 1024 chars, got %d\n' "${#got}" >&2; exit 1; }
[[ "$got" == "$big" ]] || { printf 'mismatch in roundtripped string\n' >&2; exit 1; }
