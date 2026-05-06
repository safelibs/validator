#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r9-sel-distinct-values
# @title: xmlstarlet sel sums attribute values via XPath sum()
# @description: Selects sum(@n) over a list of numbered items and asserts the printed total matches the arithmetic sum.
# @timeout: 60
# @tags: usage, xmlstarlet, xpath
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <item n="1"/>
  <item n="2"/>
  <item n="3"/>
  <item n="4"/>
</root>
XML

xmlstarlet sel -t -v 'sum(/root/item/@n)' "$tmpdir/in.xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '10'

xmlstarlet sel -t -v 'count(/root/item)' "$tmpdir/in.xml" >"$tmpdir/count"
validator_assert_contains "$tmpdir/count" '4'
