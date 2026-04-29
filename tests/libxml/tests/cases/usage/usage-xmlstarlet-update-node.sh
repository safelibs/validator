#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-update-node
# @title: xmlstarlet updates node
# @description: Updates XML text content with xmlstarlet edit and verifies the new serialized value.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-update-node"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><item>old</item></root>' >"$tmpdir/in.xml"
xmlstarlet ed -u '/root/item' -v new "$tmpdir/in.xml" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '<item>new</item>'
