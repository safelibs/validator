#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r21-pyx-output-emits-bracketed-tags
# @title: xmlstarlet pyx emits open-paren/close-paren tag lines for each element start/end
# @description: Runs xmlstarlet pyx on a small XML tree and asserts the output contains lines starting with '(' (element open) and ')' (element close) for the root tag — pinning xmlstarlet's libxml2-backed PYX SAX-stream emission on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, xmlstarlet, pyx, r21
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root><item>x</item></root>
XML

xmlstarlet pyx "$tmpdir/in.xml" >"$tmpdir/out.pyx"
[[ -s "$tmpdir/out.pyx" ]]
grep -q '^(root$' "$tmpdir/out.pyx" || { echo "expected '(root' line"; cat "$tmpdir/out.pyx" >&2; exit 1; }
grep -q '^)root$' "$tmpdir/out.pyx" || { echo "expected ')root' line"; cat "$tmpdir/out.pyx" >&2; exit 1; }
grep -q '^(item$' "$tmpdir/out.pyx" || { echo "expected '(item' line"; cat "$tmpdir/out.pyx" >&2; exit 1; }
