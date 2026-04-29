#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-delete-node
# @title: xmlstarlet deletes node
# @description: Deletes one XML node with xmlstarlet edit and verifies remaining content.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-delete-node"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><item>A</item><item>B</item></root>' >"$tmpdir/in.xml"
xmlstarlet ed -d '/root/item[1]' "$tmpdir/in.xml" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '<item>B</item>'
if grep -Fq '<item>A</item>' "$tmpdir/out"; then exit 1; fi
