#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r17-xpath-compiled-vs-adhoc-equiv
# @title: lxml etree.XPath compiled expression returns the same results as Element.xpath
# @description: Compiles an XPath via etree.XPath once and evaluates it against a tree, then evaluates the same XPath ad-hoc via Element.xpath, and asserts both return the same list of element texts — pinning the compiled-vs-adhoc result equivalence contract.
# @timeout: 60
# @tags: usage, xml, python, xpath
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree
root = etree.fromstring(b'<r><i k="x">a</i><i k="y">b</i><i k="x">c</i></r>')
expr = etree.XPath('//i[@k="x"]')
compiled = [e.text for e in expr(root)]
adhoc = [e.text for e in root.xpath('//i[@k="x"]')]
print('compiled=' + ','.join(compiled))
print('adhoc=' + ','.join(adhoc))
print('equal=' + str(compiled == adhoc))
PY

validator_assert_contains "$tmpdir/out" 'compiled=a,c'
validator_assert_contains "$tmpdir/out" 'adhoc=a,c'
validator_assert_contains "$tmpdir/out" 'equal=True'
