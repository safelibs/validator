#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-concat-values
# @title: xmlstarlet concatenates values
# @description: Concatenates XML values with xmlstarlet select and verifies the combined string.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-concat-values"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><item>A</item><item>B</item></root>' >"$tmpdir/in.xml"
xmlstarlet sel -t -v 'concat(/root/item[1], "-", /root/item[2])' "$tmpdir/in.xml" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'A-B'
