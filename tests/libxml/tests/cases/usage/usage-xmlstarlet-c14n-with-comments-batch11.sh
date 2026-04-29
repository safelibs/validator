#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-c14n-with-comments-batch11
# @title: xmlstarlet c14n with comments
# @description: Canonicalizes XML with comments preserved through xmlstarlet.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-c14n-with-comments-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/items.xml" <<'XML'
<root><item id="a" weight="2">Alpha</item><item id="b" weight="3">Beta</item><!--drop--><?note ok?></root>
XML

xmlstarlet c14n --with-comments "$tmpdir/items.xml" >"$tmpdir/out.xml"
validator_assert_contains "$tmpdir/out.xml" '<!--drop-->'
