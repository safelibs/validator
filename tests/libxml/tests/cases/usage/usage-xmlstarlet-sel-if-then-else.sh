#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-sel-if-then-else
# @title: xmlstarlet sel template if/then/else branching
# @description: Runs xmlstarlet sel with a template that walks /root/item and uses -if, -then, and -else to emit one literal for items above a numeric threshold and another for items below it, then verifies the produced output line for each item matches the expected branch.
# @timeout: 180
# @tags: usage, xml, cli, sel
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/items.xml" <<'XML'
<root>
  <item id="a" weight="2"/>
  <item id="b" weight="3"/>
  <item id="c" weight="5"/>
  <item id="d" weight="1"/>
</root>
XML

# Emit "<id>=heavy" if weight > 2 else "<id>=light", one per item.
xmlstarlet sel -t \
  -m '/root/item' \
    -v '@id' -o '=' \
    -i '@weight > 2' -o 'heavy' -b \
    -i 'not(@weight > 2)' -o 'light' -b \
    -n \
  "$tmpdir/items.xml" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'a=light'
validator_assert_contains "$tmpdir/out" 'b=heavy'
validator_assert_contains "$tmpdir/out" 'c=heavy'
validator_assert_contains "$tmpdir/out" 'd=light'

# Exactly four output lines (one per item).
line_count=$(grep -c '=' "$tmpdir/out" || true)
[[ "$line_count" == "4" ]] || {
  printf 'expected 4 branched lines, got %s\n' "$line_count" >&2
  cat "$tmpdir/out" >&2
  exit 1
}

# 'heavy' must appear exactly twice and 'light' exactly twice.
heavy_count=$(grep -c '=heavy' "$tmpdir/out" || true)
light_count=$(grep -c '=light' "$tmpdir/out" || true)
[[ "$heavy_count" == "2" ]] || {
  printf 'expected 2 heavy, got %s\n' "$heavy_count" >&2
  exit 1
}
[[ "$light_count" == "2" ]] || {
  printf 'expected 2 light, got %s\n' "$light_count" >&2
  exit 1
}
