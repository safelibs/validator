#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-delete-attribute
# @title: xmlstarlet deletes attribute
# @description: Deletes an XML attribute with xmlstarlet edit mode and verifies the serialized element no longer carries the attribute.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-delete-attribute"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><item status="old">A</item></root>' >"$tmpdir/in.xml"
xmlstarlet ed -d '/root/item/@status' "$tmpdir/in.xml" | tee "$tmpdir/out"
if grep -Fq 'status=' "$tmpdir/out"; then
  printf 'attribute delete unexpectedly retained status attribute\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/out" '<item>A</item>'
