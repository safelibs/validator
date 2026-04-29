#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-select-if-batch11
# @title: xmlstarlet select if
# @description: Selects XML nodes by numeric attribute comparison with xmlstarlet.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-select-if-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/items.xml" <<'XML'
<root><item id="a" weight="2">Alpha</item><item id="b" weight="3">Beta</item><!--drop--><?note ok?></root>
XML

xmlstarlet sel -t -m '//item[@weight > 2]' -v @id "$tmpdir/items.xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'b'
