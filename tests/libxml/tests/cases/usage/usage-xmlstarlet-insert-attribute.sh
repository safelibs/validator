#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-insert-attribute
# @title: xmlstarlet inserts attribute
# @description: Adds an XML attribute with xmlstarlet edit and verifies serialized output.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-insert-attribute"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><item>1</item></root>' >"$tmpdir/in.xml"
xmlstarlet ed -i '/root/item' -t attr -n status -v ok "$tmpdir/in.xml" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'status="ok"'
