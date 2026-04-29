#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-select-count
# @title: xmlstarlet selects count
# @description: Counts XML nodes with xmlstarlet select and verifies the numeric result.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-select-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><item>A</item><item>B</item></root>' >"$tmpdir/in.xml"
xmlstarlet sel -t -v 'count(/root/item)' "$tmpdir/in.xml" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2'
