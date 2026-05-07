#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r12-xpath-boolean-result
# @title: lxml XPath returns native Python bool for boolean()-wrapped expressions
# @description: Evaluates two XPath expressions wrapped with boolean() against a tiny tree and asserts the results are returned as Python's True / False (not as a string or int), confirming lxml maps XPath xs:boolean to bool.
# @timeout: 60
# @tags: usage, xml, python, xpath
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b'<r><a/><a/></r>')
yes = doc.xpath('boolean(/r/a)')
no = doc.xpath('boolean(/r/missing)')
print('yes=' + repr(yes))
print('no=' + repr(no))
print('yes_type=' + type(yes).__name__)
print('no_type=' + type(no).__name__)
PY

validator_assert_contains "$tmpdir/out" 'yes=True'
validator_assert_contains "$tmpdir/out" 'no=False'
validator_assert_contains "$tmpdir/out" 'yes_type=bool'
validator_assert_contains "$tmpdir/out" 'no_type=bool'
