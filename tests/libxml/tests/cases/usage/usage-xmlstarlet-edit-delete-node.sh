#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-edit-delete-node
# @title: xmlstarlet edit delete node
# @description: Deletes an XML node with xmlstarlet edit and verifies the removed text no longer appears in the output.
# @timeout: 180
# @tags: usage, xml, xmlstarlet
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-edit-delete-node"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/input.xml"
cat >"$xml" <<'XML'
<root xmlns:h="urn:hello"><item id="a">alpha</item><item id="b">beta</item><group active="yes"><value>3</value></group><h:note>hello-note</h:note></root>
XML

xmlstarlet ed -d '/root/item[@id="a"]' "$xml" >"$tmpdir/out.xml"
validator_assert_contains "$tmpdir/out.xml" 'beta'
if grep -Fq 'alpha' "$tmpdir/out.xml"; then
  printf 'deleted node unexpectedly remained in XML output\n' >&2
  exit 1
fi
