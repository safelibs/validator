#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r19-parser-remove-blank-text-drops-whitespace
# @title: lxml XMLParser remove_blank_text drops indentation-only text between elements
# @description: Parses an indented XML document with etree.XMLParser(remove_blank_text=True), serializes the result, and asserts the output does not contain whitespace between sibling element tags — locking in the libxml2 blank-text suppression path through lxml.
# @timeout: 60
# @tags: usage, xml, python, parser, blank-text, r19
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

src = b'''<r>
  <a>x</a>
  <b>y</b>
</r>'''
parser = etree.XMLParser(remove_blank_text=True)
doc = etree.fromstring(src, parser)
serialized = etree.tostring(doc).decode('ascii')
print('out=' + serialized)
PY

# Expect siblings to be tightly adjacent: <a>x</a><b>y</b>
grep -Fq '<a>x</a><b>y</b>' "$tmpdir/out"
