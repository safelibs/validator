#!/usr/bin/env bash
# @testcase: usage-jshon-r21-large-integer-2pow53-roundtrip
# @title: jshon extracts the integer 9007199254740992 (2^53) without precision loss
# @description: Pipes the JSON array [9007199254740992] through jshon -e 0 -u and asserts the captured output equals exactly "9007199254740992" - locking in libjansson's integer parsing/round-tripping at the IEEE-754 double 2^53 boundary, well above prior tests that exercised only smaller large-integer values.
# @timeout: 30
# @tags: usage, json, cli, integer, boundary, r21
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

got=$(printf '[9007199254740992]' | jshon -e 0 -u)
[[ "$got" == "9007199254740992" ]] || {
    printf 'expected 9007199254740992, got %q\n' "$got" >&2
    exit 1
}
