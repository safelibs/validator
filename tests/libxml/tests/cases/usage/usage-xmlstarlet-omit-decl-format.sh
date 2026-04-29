#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-omit-decl-format
# @title: xmlstarlet omit declaration format
# @description: Exercises xmlstarlet omit declaration format through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-xmlstarlet-omit-decl-format"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><item>A</item></root>' >"$tmpdir/in.xml"
xmlstarlet sel -t -c '/root' "$tmpdir/in.xml" >"$tmpdir/out"
if grep -Fq '<?xml' "$tmpdir/out"; then exit 1; fi
validator_assert_contains "$tmpdir/out" '<item>A</item>'
