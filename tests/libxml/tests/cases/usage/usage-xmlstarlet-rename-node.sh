#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-rename-node
# @title: xmlstarlet renames node
# @description: Renames an XML element with xmlstarlet edit and verifies the new tag name.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-rename-node"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><item>A</item></root>' >"$tmpdir/in.xml"
xmlstarlet ed -r '/root/item' -v entry "$tmpdir/in.xml" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '<entry>A</entry>'
