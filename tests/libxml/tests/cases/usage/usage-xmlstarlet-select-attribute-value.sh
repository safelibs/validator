#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-select-attribute-value
# @title: xmlstarlet select attribute value
# @description: Selects an XML attribute with xmlstarlet and verifies the emitted attribute value.
# @timeout: 180
# @tags: usage, xml
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-select-attribute-value"
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

xmlstarlet sel -t -v '/root/item[2]/@id' "$xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'b'
