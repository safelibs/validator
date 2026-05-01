#!/usr/bin/env bash
# @testcase: usage-python3-lxml-makeelement-namespaced-r8
# @title: lxml Element.makeelement with namespace map
# @description: Creates a child element via Element.makeelement using an explicit nsmap that introduces a new prefix, attaches it to a root carrying a different default namespace, and verifies the serialized output emits both prefix declarations and uses Clark notation for the new element's tag in element.tag readout.
# @timeout: 120
# @tags: usage, xml, python, namespaces
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

NSMAP_ROOT = {None: 'urn:r'}
NSMAP_CHILD = {'c': 'urn:c'}

root = etree.Element('{urn:r}root', nsmap=NSMAP_ROOT)
child = root.makeelement('{urn:c}entry', attrib={}, nsmap=NSMAP_CHILD)
child.text = 'hello'
root.append(child)

print('child_tag=' + child.tag)
print('child_prefix=' + (child.prefix or ''))
print('serialized=' + etree.tostring(root, encoding='unicode'))
PY

validator_assert_contains "$tmpdir/out" 'child_tag={urn:c}entry'
validator_assert_contains "$tmpdir/out" 'child_prefix=c'
validator_assert_contains "$tmpdir/out" 'xmlns="urn:r"'
validator_assert_contains "$tmpdir/out" 'xmlns:c="urn:c"'
validator_assert_contains "$tmpdir/out" '<c:entry'
validator_assert_contains "$tmpdir/out" '>hello</c:entry>'
