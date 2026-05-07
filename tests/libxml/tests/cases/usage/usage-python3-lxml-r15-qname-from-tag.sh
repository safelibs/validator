#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r15-qname-from-tag
# @title: lxml etree.QName decomposes a Clark-notation tag into namespace and localname
# @description: Constructs an etree.QName from a namespace and localname, asserts its .text returns the Clark-notation form "{ns}local", that .localname and .namespace round-trip the inputs, and that QName(element) on a parsed namespaced element recovers the same Clark form.
# @timeout: 60
# @tags: usage, xml, python, qname
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

q = etree.QName('urn:r15', 'item')
print('text=' + q.text)
print('localname=' + q.localname)
print('namespace=' + str(q.namespace))

doc = etree.fromstring(b'<root xmlns:a="urn:r15"><a:item/></root>')
child = doc[0]
qc = etree.QName(child)
print('child_text=' + qc.text)
print('child_localname=' + qc.localname)
print('child_namespace=' + str(qc.namespace))
PY

validator_assert_contains "$tmpdir/out" 'text={urn:r15}item'
validator_assert_contains "$tmpdir/out" 'localname=item'
validator_assert_contains "$tmpdir/out" 'namespace=urn:r15'
validator_assert_contains "$tmpdir/out" 'child_text={urn:r15}item'
validator_assert_contains "$tmpdir/out" 'child_localname=item'
validator_assert_contains "$tmpdir/out" 'child_namespace=urn:r15'
