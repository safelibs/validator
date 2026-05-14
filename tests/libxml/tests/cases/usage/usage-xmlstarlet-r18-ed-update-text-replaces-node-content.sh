#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r18-ed-update-text-replaces-node-content
# @title: xmlstarlet ed -u replaces a target node's text content in place
# @description: Runs xmlstarlet ed -u '//item/text()' to overwrite the text inside an <item> element with a new value, then re-parses the output with xmlstarlet sel and asserts the new value is observed.
# @timeout: 60
# @tags: usage, xmlstarlet, edit, update, r18
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root><item>old</item></root>
XML

xmlstarlet ed -u '//item' -v 'new' "$tmpdir/in.xml" >"$tmpdir/out.xml"
got=$(xmlstarlet sel -t -v '//item' -n "$tmpdir/out.xml")
[[ "$got" == "new" ]] || { printf 'unexpected value: %q\n' "$got" >&2; cat "$tmpdir/out.xml" >&2; exit 1; }
