#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r19-element-maker-builds-namespaced-tree
# @title: lxml builder.ElementMaker constructs a nested namespaced element with attributes
# @description: Uses lxml.builder.ElementMaker with a namespace and nsmap to build a root containing a single child carrying an attribute, then serializes the tree and asserts the namespace declaration and child element both appear with the expected prefix.
# @timeout: 60
# @tags: usage, xml, python, builder, r19
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree
from lxml.builder import ElementMaker

E = ElementMaker(namespace='urn:example:x', nsmap={'x': 'urn:example:x'})
root = E.box(E.item('hello', kind='greet'))
blob = etree.tostring(root).decode('ascii')
print('xml=' + blob)
PY

grep -Fq 'xmlns:x="urn:example:x"' "$tmpdir/out"
grep -Fq 'kind="greet"' "$tmpdir/out"
grep -Fq '<x:item' "$tmpdir/out"
