#!/usr/bin/env bash
# @testcase: usage-python3-lxml-element-maker
# @title: lxml element maker
# @description: Builds XML with lxml.builder element helpers and verifies serialized output.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-element-maker"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
from lxml.builder import E
root = E.root(E.item("value"))
print(etree.tostring(root).decode())
PY
validator_assert_contains "$tmpdir/out" '<item>value</item>'
