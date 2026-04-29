#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-format-indent-batch11
# @title: xmlstarlet format indent
# @description: Formats XML with a two-space indent through xmlstarlet.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-format-indent-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/items.xml" <<'XML'
<root><item id="a" weight="2">Alpha</item><item id="b" weight="3">Beta</item><!--drop--><?note ok?></root>
XML

xmlstarlet fo -s 2 "$tmpdir/items.xml" >"$tmpdir/out.xml"
validator_assert_contains "$tmpdir/out.xml" '  <item'
