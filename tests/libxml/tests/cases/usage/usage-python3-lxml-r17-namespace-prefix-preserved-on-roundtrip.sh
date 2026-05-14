#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r17-namespace-prefix-preserved-on-roundtrip
# @title: lxml etree.XML with a declared namespace prefix preserves the prefix on serialization
# @description: Parses an XML string declaring xmlns:ns0='http://example.org/ns' with an element using that prefix, serializes the tree via tostring, and asserts the output contains the same 'ns0:' prefix and namespace URI — exercising libxml2's namespace bookkeeping through lxml.
# @timeout: 60
# @tags: usage, xml, python, namespace
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

src = b'<root xmlns:ns0="http://example.org/ns"><ns0:child>v</ns0:child></root>'
el = etree.XML(src)
print('s=' + etree.tostring(el, encoding='unicode'))
PY

validator_assert_contains "$tmpdir/out" 'xmlns:ns0="http://example.org/ns"'
validator_assert_contains "$tmpdir/out" '<ns0:child>v</ns0:child>'
