#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r20-sel-name-fn-returns-element-name
# @title: xmlstarlet sel -t -v 'name(//item[1])' returns the literal string 'item'
# @description: Runs xmlstarlet sel -t -v with an XPath name() call targeting the first <item> element and asserts the printed output is exactly 'item', exercising the libxml2 XPath name() function through the xmlstarlet select pipeline.
# @timeout: 60
# @tags: usage, xmlstarlet, sel, name-fn, r20
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root><item>a</item><item>b</item></root>
XML

got=$(xmlstarlet sel -t -v 'name(//item[1])' "$tmpdir/in.xml")
[[ "$got" == "item" ]] || { printf 'unexpected name() output: %q\n' "$got" >&2; exit 1; }
