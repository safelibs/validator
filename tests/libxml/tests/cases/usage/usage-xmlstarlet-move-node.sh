#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-move-node
# @title: xmlstarlet moves node
# @description: Moves an XML node with xmlstarlet edit mode and verifies the relocated node appears under the target element.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-move-node"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><group/><item>A</item></root>' >"$tmpdir/in.xml"
xmlstarlet ed -m '/root/item' '/root/group' "$tmpdir/in.xml" | tee "$tmpdir/out"
xmlstarlet sel -t -v 'string(/root/group/item)' "$tmpdir/out" >"$tmpdir/value"
grep -Fxq 'A' "$tmpdir/value"
