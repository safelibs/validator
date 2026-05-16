#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r21-sel-string-fn-emits-text-content
# @title: xmlstarlet sel -t -v string(/r) emits the concatenated text content of the root
# @description: Runs xmlstarlet sel -t -v 'string(/r)' against a document with text spread across two siblings and asserts the result equals the concatenated text content — pinning xmlstarlet's libxml2 XPath string() function on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, xmlstarlet, sel, xpath, string-fn, r21
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<r><a>foo</a><b>bar</b></r>
XML

out=$(xmlstarlet sel -t -v 'string(/r)' "$tmpdir/in.xml")
[[ "$out" == "foobar" ]] || { printf 'expected "foobar", got: %s\n' "$out" >&2; exit 1; }
