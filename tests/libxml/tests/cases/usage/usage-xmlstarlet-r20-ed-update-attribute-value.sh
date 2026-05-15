#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r20-ed-update-attribute-value
# @title: xmlstarlet ed -u replaces an existing attribute's value in-document
# @description: Starts from an XML document with item[@status="old"], runs xmlstarlet ed -u //item/@status -v new and asserts that querying //item/@status on the result reads back 'new', exercising the libxml2-backed attribute update path in xmlstarlet ed.
# @timeout: 60
# @tags: usage, xmlstarlet, ed, update-attribute, r20
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root><item status="old">v</item></root>
XML

xmlstarlet ed -u '//item/@status' -v 'new' "$tmpdir/in.xml" >"$tmpdir/out.xml"
got=$(xmlstarlet sel -t -v '//item/@status' "$tmpdir/out.xml")
[[ "$got" == "new" ]] || { printf 'unexpected attribute value: %q\n' "$got" >&2; exit 1; }
