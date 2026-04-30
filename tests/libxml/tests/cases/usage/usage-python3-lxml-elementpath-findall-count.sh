#!/usr/bin/env bash
# @testcase: usage-python3-lxml-elementpath-findall-count
# @title: lxml ElementPath findall count
# @description: Uses lxml ElementPath findall on a tree and verifies the exact element count and the joined text values returned by find/findtext on the same path.
# @timeout: 120
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-elementpath-findall-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' >"$tmpdir/out"
from lxml import etree
root = etree.XML(
    b'<root>'
    b'<item id="a"><name>alpha</name></item>'
    b'<item id="b"><name>beta</name></item>'
    b'<item id="c"><name>gamma</name></item>'
    b'<other><name>skip</name></other>'
    b'</root>'
)
items = root.findall('item')
print("count=%d" % len(items))
print("first=%s" % root.find('item').get('id'))
print("first_name=%s" % root.findtext('item/name'))
print("names=%s" % ",".join(e.text for e in root.findall('item/name')))
PY

validator_assert_contains "$tmpdir/out" 'count=3'
validator_assert_contains "$tmpdir/out" 'first=a'
validator_assert_contains "$tmpdir/out" 'first_name=alpha'
validator_assert_contains "$tmpdir/out" 'names=alpha,beta,gamma'
