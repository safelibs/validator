#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-append-attribute
# @title: xmlstarlet append attribute
# @description: Exercises xmlstarlet append attribute through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-append-attribute"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><item>A</item></root>' >"$tmpdir/in.xml"
xmlstarlet ed -i '/root/item' -t attr -n code -v 'A1' "$tmpdir/in.xml" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'code="A1"'
