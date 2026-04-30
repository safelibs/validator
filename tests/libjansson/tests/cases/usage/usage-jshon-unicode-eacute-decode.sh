#!/usr/bin/env bash
# @testcase: usage-jshon-unicode-eacute-decode
# @title: jshon decodes escaped e-acute
# @description: Reads an escaped é inside a JSON string and verifies jshon -u emits the UTF-8 e-acute byte sequence.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-unicode-eacute-decode"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# JSON-escaped lowercase e-acute (U+00E9).
printf '{"label":"caf\\u00e9"}' >"$tmpdir/input.json"

jshon -F "$tmpdir/input.json" -e label -u >"$tmpdir/out"

# UTF-8 encoding of U+00E9 is 0xC3 0xA9.
expected=$(printf 'caf\xc3\xa9')
if ! grep -Fxq -- "$expected" "$tmpdir/out"; then
  printf 'expected UTF-8 e-acute decode, got:\n' >&2
  od -c "$tmpdir/out" >&2
  exit 1
fi
