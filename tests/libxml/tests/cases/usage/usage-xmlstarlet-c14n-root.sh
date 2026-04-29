#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-c14n-root
# @title: xmlstarlet c14n root
# @description: Canonicalizes XML with xmlstarlet c14n and verifies the canonical output retains the namespaced note element.
# @timeout: 180
# @tags: usage, xml
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-c14n-root"
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

xmlstarlet c14n "$xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '<ns:note>namespaced</ns:note>'
