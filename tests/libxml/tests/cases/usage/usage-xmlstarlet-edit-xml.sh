#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-edit-xml
# @title: xmlstarlet edit xml
# @description: Runs xmlstarlet edit xml behavior through libxml2.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    validator_make_fixture "$tmpdir/in.xml" "<root><item name=\"alpha\">1</item><item name=\"beta\">2</item></root>"
xmlstarlet ed -u '/root/item[@name="beta"]' -v 22 "$tmpdir/in.xml" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '22'
