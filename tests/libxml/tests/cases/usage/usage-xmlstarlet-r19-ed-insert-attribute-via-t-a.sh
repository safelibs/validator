#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r19-ed-insert-attribute-via-t-a
# @title: xmlstarlet ed -i with -t attr adds a new attribute to an element via XPath
# @description: Runs xmlstarlet ed -i //item -t attr -n status -v active to insert a 'status' attribute on the //item node, then queries the resulting document with xmlstarlet sel and asserts the attribute value reads back as 'active'.
# @timeout: 60
# @tags: usage, xmlstarlet, edit, attribute, r19
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root><item>v</item></root>
XML

xmlstarlet ed -i '//item' -t attr -n status -v 'active' "$tmpdir/in.xml" >"$tmpdir/out.xml"
got=$(xmlstarlet sel -t -v '//item/@status' "$tmpdir/out.xml")
[[ "$got" == "active" ]] || {
    printf 'unexpected attribute value: %q\n' "$got" >&2
    cat "$tmpdir/out.xml" >&2
    exit 1
}
