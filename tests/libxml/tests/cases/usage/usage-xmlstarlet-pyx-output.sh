#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-pyx-output
# @title: xmlstarlet pyx output
# @description: Converts XML to PYX line-oriented form with xmlstarlet pyx and verifies element and text records appear in the output.
# @timeout: 180
# @tags: usage, xml
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-pyx-output"
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

xmlstarlet pyx "$xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '(root'
validator_assert_contains "$tmpdir/out" '-alpha'
