#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-unescape-text
# @title: xmlstarlet unesc text roundtrip
# @description: Escapes a string with xmlstarlet esc, unescapes the result with xmlstarlet unesc, and verifies the recovered text matches the original byte-for-byte.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# xmlstarlet's `esc` only rewrites the markup-significant trio < > & on
# Ubuntu 24.04 (single and double quotes pass through unchanged).
original='a<b & c>d'

xmlstarlet esc "$original" >"$tmpdir/escaped"
xmlstarlet unesc "$(cat "$tmpdir/escaped")" >"$tmpdir/unescaped"

validator_assert_contains "$tmpdir/escaped" 'a&lt;b &amp; c&gt;d'

recovered=$(cat "$tmpdir/unescaped")
[[ "$recovered" == "$original" ]] || {
  printf 'roundtrip mismatch: %q vs %q\n' "$recovered" "$original" >&2
  exit 1
}

printf 'roundtrip-ok\n' >"$tmpdir/marker"
validator_assert_contains "$tmpdir/marker" 'roundtrip-ok'
