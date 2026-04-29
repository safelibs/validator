#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-append-node
# @title: xmlstarlet appends node
# @description: Appends a new XML element with xmlstarlet edit and verifies the inserted node.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-append-node"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><item>A</item></root>' >"$tmpdir/in.xml"
xmlstarlet ed -s '/root' -t elem -n extra -v B "$tmpdir/in.xml" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '<extra>B</extra>'
