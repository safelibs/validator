#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-select-attribute
# @title: xmlstarlet select attribute
# @description: Selects an XML attribute with xmlstarlet and verifies the returned value.
# @timeout: 180
# @tags: usage, xml, xmlstarlet
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-select-attribute"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/input.xml"
cat >"$xml" <<'XML'
<root xmlns:h="urn:hello"><item id="a">alpha</item><item id="b">beta</item><group active="yes"><value>3</value></group><h:note>hello-note</h:note></root>
XML

xmlstarlet sel -t -v '/root/item[@id="b"]/@id' "$xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'b'
