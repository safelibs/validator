#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xpath-string-length-r7
# @title: lxml XPath string-length and concat
# @description: Evaluates the XPath string-length() function on a selected element text and combines concat() with normalize-space() to produce a derived string, verifying both libxml2 XPath string functions return their canonical results.
# @timeout: 120
# @tags: usage, xml, python, xpath
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b"<root><name>   alpha   beta   </name><suffix>!</suffix></root>")

length = doc.xpath('string-length(normalize-space(/root/name))')
combined = doc.xpath('concat(normalize-space(/root/name), /root/suffix)')

assert length == 10.0, length
assert combined == 'alpha beta!', combined

print("length=%d" % int(length))
print("combined=" + combined)
PY

validator_assert_contains "$tmpdir/out" 'length=10'
validator_assert_contains "$tmpdir/out" 'combined=alpha beta!'
