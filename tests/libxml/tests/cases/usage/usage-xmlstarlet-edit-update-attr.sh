#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-edit-update-attr
# @title: xmlstarlet edit update attribute
# @description: Updates an XML attribute with xmlstarlet edit and verifies the rewritten output.
# @timeout: 180
# @tags: usage, xml, xmlstarlet
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-edit-update-attr"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/input.xml"
cat >"$xml" <<'XML'
<root xmlns:h="urn:hello"><item id="a">alpha</item><item id="b">beta</item><group active="yes"><value>3</value></group><h:note>hello-note</h:note></root>
XML

xmlstarlet ed -u '/root/group/@active' -v 'no' "$xml" >"$tmpdir/out.xml"
validator_assert_contains "$tmpdir/out.xml" 'active="no"'
