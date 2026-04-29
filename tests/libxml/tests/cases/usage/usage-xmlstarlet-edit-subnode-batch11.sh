#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-edit-subnode-batch11
# @title: xmlstarlet edit subnode
# @description: Adds a subnode to XML with xmlstarlet edit.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-edit-subnode-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/items.xml" <<'XML'
<root><item id="a" weight="2">Alpha</item><item id="b" weight="3">Beta</item><!--drop--><?note ok?></root>
XML

xmlstarlet ed -s /root -t elem -n extra -v value "$tmpdir/items.xml" >"$tmpdir/out.xml"
validator_assert_contains "$tmpdir/out.xml" '<extra>value</extra>'
