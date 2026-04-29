#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-update-attribute
# @title: xmlstarlet update attribute
# @description: Exercises xmlstarlet update attribute through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-update-attribute"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><item status="old">A</item></root>' >"$tmpdir/in.xml"
xmlstarlet ed -u '/root/item/@status' -v 'ok' "$tmpdir/in.xml" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'status="ok"'
