#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-select-namespaced-tag
# @title: xmlstarlet namespaced tag select
# @description: Reads a namespaced element with xmlstarlet sel and a registered namespace prefix and verifies the selected text.
# @timeout: 180
# @tags: usage, xml
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-select-namespaced-tag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/doc.xml"
cat >"$xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<root xmlns:m="urn:meta">
  <item id="a" weight="2">alpha</item>
  <item id="b" weight="3">beta</item>
  <item id="c" weight="5">gamma</item>
  <m:tag>meta-tag</m:tag>
</root>
XML

xmlstarlet sel -N m='urn:meta' -t -v 'string(/root/m:tag)' "$xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'meta-tag'
