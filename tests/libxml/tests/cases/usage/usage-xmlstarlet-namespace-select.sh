#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-namespace-select
# @title: xmlstarlet namespace select
# @description: Selects namespaced XML content with xmlstarlet namespace bindings.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-namespace-select"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root xmlns:a="urn:a"><a:item>namespaced</a:item></root>
XML
xmlstarlet sel -N a=urn:a -t -v '/root/a:item' "$tmpdir/in.xml" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'namespaced'
