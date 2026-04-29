#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-edit-add-attribute
# @title: xmlstarlet edit add attribute
# @description: Adds an XML attribute with xmlstarlet ed and verifies the new attribute value in the updated document.
# @timeout: 180
# @tags: usage, xml
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-edit-add-attribute"
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

xmlstarlet ed -s '/root/item[1]' -t attr -n kind -v primary "$xml" >"$tmpdir/out.xml"
xmlstarlet sel -t -v '/root/item[1]/@kind' "$tmpdir/out.xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'primary'
