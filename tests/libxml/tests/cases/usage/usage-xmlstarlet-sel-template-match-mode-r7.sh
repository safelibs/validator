#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-sel-template-match-mode-r7
# @title: xmlstarlet sel template -m -c -v sequence
# @description: Runs xmlstarlet sel with a -t template that uses -m to iterate item elements, -c to copy a nested element subtree per match, -v to extract an attribute value, and -n for newline separators, and verifies the emitted lines exactly match the expected per-item rendering.
# @timeout: 120
# @tags: usage, xml, cli, xmlstarlet, xpath
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <item id="a"><label>alpha</label></item>
  <item id="b"><label>beta</label></item>
  <item id="c"><label>gamma</label></item>
</root>
XML

xmlstarlet sel -t \
  -m '/root/item' \
    -v '@id' -o '|' \
    -c 'label' \
    -n \
  "$tmpdir/in.xml" >"$tmpdir/out"

[[ "$(wc -l <"$tmpdir/out")" == "3" ]] || {
  printf 'expected 3 output lines, got %s\n' "$(wc -l <"$tmpdir/out")" >&2
  cat "$tmpdir/out" >&2
  exit 1
}

validator_assert_contains "$tmpdir/out" 'a|<label>alpha</label>'
validator_assert_contains "$tmpdir/out" 'b|<label>beta</label>'
validator_assert_contains "$tmpdir/out" 'c|<label>gamma</label>'
