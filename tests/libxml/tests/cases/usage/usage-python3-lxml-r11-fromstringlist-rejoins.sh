#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r11-fromstringlist-rejoins
# @title: lxml etree.fromstringlist joins arbitrary chunk boundaries into one tree
# @description: Splits a complete XML document into chunks that intentionally cross tag boundaries, parses with etree.fromstringlist, and asserts the resulting root element name and child text values match the original document.
# @timeout: 60
# @tags: usage, xml, python, parse
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

chunks = ["<roo", "t><c>x", "</c><c>y</c></", "root>"]
root = etree.fromstringlist(chunks)
print('tag=' + root.tag)
print('children=' + ','.join(c.text for c in root))
PY

validator_assert_contains "$tmpdir/out" 'tag=root'
validator_assert_contains "$tmpdir/out" 'children=x,y'
