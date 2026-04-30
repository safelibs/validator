#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-sel-copy-match
# @title: xmlstarlet sel template copy match
# @description: Uses xmlstarlet sel -t -m //x -c "." to copy each matched element verbatim into the output stream and verifies that the emitted XML contains every original element with its attributes and text intact.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <item id="a" weight="2">alpha</item>
  <item id="b" weight="3">beta</item>
  <item id="c" weight="5">gamma</item>
  <skip>nope</skip>
</root>
XML

xmlstarlet sel -t -m '//item' -c '.' -n "$tmpdir/in.xml" >"$tmpdir/out"

# Each matched item must appear verbatim, with attributes and text preserved.
validator_assert_contains "$tmpdir/out" '<item id="a" weight="2">alpha</item>'
validator_assert_contains "$tmpdir/out" '<item id="b" weight="3">beta</item>'
validator_assert_contains "$tmpdir/out" '<item id="c" weight="5">gamma</item>'

# The non-matched <skip> element must not be copied.
if grep -F '<skip>' "$tmpdir/out" >/dev/null; then
  printf 'unexpected <skip> element in copy output\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

count=$(grep -c '<item ' "$tmpdir/out" || true)
[[ "$count" == "3" ]] || {
  printf 'expected 3 copied items, got %s\n' "$count" >&2
  cat "$tmpdir/out" >&2
  exit 1
}
