#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r20-xpath-count-fn-returns-integer-string
# @title: lxml XPath count(//item) returns a Python float equal to the literal child count
# @description: Builds a tree with exactly three <item> children, evaluates the XPath count(//item) via tree.xpath, and asserts the returned value is a Python float of 3.0 — pinning libxml2's count() return-type contract through lxml's XPath bindings.
# @timeout: 60
# @tags: usage, xml, python, xpath, count, r20
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from lxml import etree

root = etree.fromstring(b'<r><item/><item/><item/></r>')
got = root.xpath('count(//item)')
assert isinstance(got, float), (got, type(got))
assert got == 3.0, got
PY
