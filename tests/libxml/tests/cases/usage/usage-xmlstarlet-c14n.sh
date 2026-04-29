#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-c14n
# @title: xmlstarlet canonical XML
# @description: Canonicalizes XML with xmlstarlet and verifies stable element output.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-c14n"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root b="2" a="1"><item>ok</item></root>' >"$tmpdir/in.xml"
xmlstarlet c14n "$tmpdir/in.xml" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '<root a="1" b="2">'
