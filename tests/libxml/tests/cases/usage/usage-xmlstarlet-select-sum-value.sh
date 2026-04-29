#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-select-sum-value
# @title: xmlstarlet select numeric sum
# @description: Evaluates an XPath numeric sum with xmlstarlet and verifies the computed value.
# @timeout: 180
# @tags: usage, xml, xmlstarlet
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-select-sum-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/input.xml"
cat >"$xml" <<'XML'
<root xmlns:h="urn:hello"><item id="a">alpha</item><item id="b">beta</item><group active="yes"><value>3</value></group><h:note>hello-note</h:note></root>
XML

xmlstarlet sel -t -v 'sum(/root/group/value)' "$xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '3'
