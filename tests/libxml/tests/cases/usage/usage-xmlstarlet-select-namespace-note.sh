#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-select-namespace-note
# @title: xmlstarlet namespaced note select
# @description: Queries a namespaced XML element through xmlstarlet and verifies the selected note text.
# @timeout: 180
# @tags: usage, xml
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-select-namespace-note"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/input.xml"
cat >"$xml" <<'XML'
<root xmlns:h="urn:hello"><item id="a">alpha</item><item id="b">beta</item><group active="yes"><value>3</value></group><h:note>hello-note</h:note></root>
XML

xmlstarlet sel -N h='urn:hello' -t -v '/root/h:note' "$xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'hello-note'
