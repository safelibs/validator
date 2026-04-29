#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-select-text-count
# @title: xmlstarlet select text count
# @description: Counts selected XML elements with xmlstarlet XPath evaluation and verifies the emitted count.
# @timeout: 180
# @tags: usage, xml
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-select-text-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/doc.xml"
cat >"$xml" <<'XML'
<root xmlns:ns="urn:test">
  <item id="a">alpha</item>
  <item id="b">beta</item>
  <ns:note>namespaced</ns:note>
</root>
XML

xmlstarlet sel -t -v 'count(/root/item)' "$xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2'
