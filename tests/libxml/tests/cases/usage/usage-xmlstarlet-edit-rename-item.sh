#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-edit-rename-item
# @title: xmlstarlet rename item element
# @description: Renames an element with xmlstarlet ed -r and verifies the new tag is emitted while the original tag no longer appears.
# @timeout: 180
# @tags: usage, xml
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-edit-rename-item"
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

xmlstarlet ed -r '/root/item[1]' -v entry "$xml" >"$tmpdir/out.xml"
validator_assert_contains "$tmpdir/out.xml" '<entry id="a"'
if grep -Fq '<item id="a"' "$tmpdir/out.xml"; then
  printf 'rename left old item element behind\n' >&2
  exit 1
fi
