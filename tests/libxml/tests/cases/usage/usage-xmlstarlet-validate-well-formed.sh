#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-validate-well-formed
# @title: xmlstarlet validate well-formed
# @description: Runs the xmlstarlet val -w well-formedness check on a document and verifies it reports the file as valid.
# @timeout: 180
# @tags: usage, xml
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-validate-well-formed"
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

xmlstarlet val -w "$xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'valid'
