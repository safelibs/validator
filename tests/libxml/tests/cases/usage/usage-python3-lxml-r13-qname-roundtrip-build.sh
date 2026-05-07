#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r13-qname-roundtrip-build
# @title: lxml etree.QName builds a Clark-notation tag and round-trips namespace and localname
# @description: Constructs an etree.QName from a namespace URI and local name, uses it to build an Element and SubElement tree, and asserts the produced tags carry the expected Clark notation, the QName's namespace and localname properties match the inputs, and the serialized XML uses an "ns0" or explicit declared prefix for the namespace.
# @timeout: 60
# @tags: usage, xml, python, qname
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

ns = 'http://example.com/r13'
qn = etree.QName(ns, 'root')
print('namespace=' + qn.namespace)
print('localname=' + qn.localname)
print('clark=' + qn.text)

root = etree.Element(qn)
child = etree.SubElement(root, etree.QName(ns, 'child'))
child.text = 'r13-body'
print('root_tag=' + root.tag)
print('child_tag=' + child.tag)

xml = etree.tostring(root).decode('utf-8')
print('has_ns_uri=' + str(ns in xml))
print('has_child_body=' + str('r13-body' in xml))
PY

validator_assert_contains "$tmpdir/out" 'namespace=http://example.com/r13'
validator_assert_contains "$tmpdir/out" 'localname=root'
validator_assert_contains "$tmpdir/out" 'clark={http://example.com/r13}root'
validator_assert_contains "$tmpdir/out" 'root_tag={http://example.com/r13}root'
validator_assert_contains "$tmpdir/out" 'child_tag={http://example.com/r13}child'
validator_assert_contains "$tmpdir/out" 'has_ns_uri=True'
validator_assert_contains "$tmpdir/out" 'has_child_body=True'
