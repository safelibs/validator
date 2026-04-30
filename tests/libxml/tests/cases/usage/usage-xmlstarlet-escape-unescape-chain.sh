#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-escape-unescape-chain
# @title: xmlstarlet escape unescape round trip
# @description: Pipes a string containing XML metacharacters through xmlstarlet esc to produce escaped entities and then through xmlstarlet unesc to recover the original payload, asserting both the intermediate escaped form and that the round-tripped output exactly equals the input.
# @timeout: 180
# @tags: usage, xml, cli, escape
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-escape-unescape-chain"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

original='if a < b && c > d then "ok"'
printf '%s' "$original" >"$tmpdir/in.txt"

xmlstarlet esc <"$tmpdir/in.txt" >"$tmpdir/escaped.txt"
xmlstarlet unesc <"$tmpdir/escaped.txt" >"$tmpdir/roundtrip.txt"

# xmlstarlet esc replaces XML metacharacters (<, >, &). Quote characters
# (") are left untouched because they are only significant inside attribute
# values, not in element content.
validator_assert_contains "$tmpdir/escaped.txt" '&lt;'
validator_assert_contains "$tmpdir/escaped.txt" '&amp;'
validator_assert_contains "$tmpdir/escaped.txt" '&gt;'

if ! grep -Fq '<' "$tmpdir/escaped.txt"; then
  :
else
  printf 'escaped output should not contain raw <\n' >&2
  cat "$tmpdir/escaped.txt" >&2
  exit 1
fi

roundtrip=$(cat "$tmpdir/roundtrip.txt")
[[ "$roundtrip" == "$original" ]] || {
  printf 'round-trip mismatch:\n  original=%s\n  roundtrip=%s\n' "$original" "$roundtrip" >&2
  exit 1
}

printf 'roundtrip-ok\n'
