#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-elements-list-batch11
# @title: xmlstarlet elements list
# @description: Lists XML element paths with xmlstarlet el.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-elements-list-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/items.xml" <<'XML'
<root><item id="a" weight="2">Alpha</item><item id="b" weight="3">Beta</item><!--drop--><?note ok?></root>
XML

xmlstarlet el "$tmpdir/items.xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'root/item'
