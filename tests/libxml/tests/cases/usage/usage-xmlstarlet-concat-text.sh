#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-concat-text
# @title: xmlstarlet concat text
# @description: Exercises xmlstarlet concat text through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-concat-text"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><item>A</item><item>B</item></root>' >"$tmpdir/in.xml"
xmlstarlet sel -t -m '/root/item' -v . -o ',' "$tmpdir/in.xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'A,B,'
