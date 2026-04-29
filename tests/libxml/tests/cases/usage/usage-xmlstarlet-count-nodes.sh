#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-count-nodes
# @title: xmlstarlet count nodes
# @description: Counts repeated XML nodes with xmlstarlet XPath evaluation and verifies the numeric result.
# @timeout: 180
# @tags: usage, xml, xmlstarlet
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-count-nodes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/input.xml"
cat >"$xml" <<'XML'
<root xmlns:h="urn:hello"><item id="a">alpha</item><item id="b">beta</item><group active="yes"><value>3</value></group><h:note>hello-note</h:note></root>
XML

xmlstarlet sel -t -v 'count(/root/item)' "$xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2'
