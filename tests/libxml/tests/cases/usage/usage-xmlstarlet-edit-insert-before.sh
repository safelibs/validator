#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-edit-insert-before
# @title: xmlstarlet ed insert before sibling
# @description: Inserts a new sibling element before an existing node with xmlstarlet ed -i and verifies the resulting child sequence and exact node count match the expected ordering.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <item name="beta">2</item>
</root>
XML

# xmlstarlet's `ed` subcommand on Ubuntu 24.04 does not accept --nonet
# (passing it warns and then segfaults), so we omit it for ed/insert ops.
xmlstarlet ed \
  -i '/root/item[@name="beta"]' -t elem -n 'item' -v '1' \
  "$tmpdir/in.xml" >"$tmpdir/step1.xml"

xmlstarlet ed \
  -i '/root/item[1]' -t attr -n 'name' -v 'alpha' \
  "$tmpdir/step1.xml" >"$tmpdir/out.xml"

xmlstarlet sel -t -m '/root/item' -v '@name' -o '=' -v '.' -o ';' "$tmpdir/out.xml" >"$tmpdir/seq"
count=$(xmlstarlet sel -t -v 'count(/root/item)' "$tmpdir/out.xml")

[[ "$count" == "2" ]] || {
  printf 'expected 2 items, got %s\n' "$count" >&2
  exit 1
}

validator_assert_contains "$tmpdir/seq" 'alpha=1;beta=2;'
