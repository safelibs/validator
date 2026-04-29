#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-edit-append-node
# @title: xmlstarlet edit append node
# @description: Appends a new element with xmlstarlet ed and verifies the inserted node text in the updated document.
# @timeout: 180
# @tags: usage, xml
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-edit-append-node"
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

xmlstarlet ed -s '/root' -t elem -n extra -v tail "$xml" >"$tmpdir/out.xml"
xmlstarlet sel -t -v 'string(/root/extra)' "$tmpdir/out.xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'tail'
