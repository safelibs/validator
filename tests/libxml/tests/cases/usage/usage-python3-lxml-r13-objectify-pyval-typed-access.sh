#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r13-objectify-pyval-typed-access
# @title: lxml.objectify exposes typed pyval accessors for int/float/bool/str leaf elements
# @description: Parses a small typed document with lxml.objectify, asserts each leaf's pyval is the correct native Python type (int, float, bool, str), and verifies arithmetic on the int/float pyvals matches the expected sum so the typed access path is fully exercised.
# @timeout: 60
# @tags: usage, xml, python, objectify
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import objectify

xml = b'<root><n>42</n><x>3.5</x><flag>true</flag><label>hello</label></root>'
root = objectify.fromstring(xml)

print('n_type=' + type(root.n.pyval).__name__)
print('x_type=' + type(root.x.pyval).__name__)
print('flag_type=' + type(root.flag.pyval).__name__)
print('label_type=' + type(root.label.pyval).__name__)

print('n_value=' + str(root.n.pyval))
print('flag_value=' + str(root.flag.pyval))
print('sum_n_x=' + str(root.n.pyval + root.x.pyval))
print('label_value=' + root.label.pyval)
PY

validator_assert_contains "$tmpdir/out" 'n_type=int'
validator_assert_contains "$tmpdir/out" 'x_type=float'
validator_assert_contains "$tmpdir/out" 'flag_type=bool'
validator_assert_contains "$tmpdir/out" 'label_type=str'
validator_assert_contains "$tmpdir/out" 'n_value=42'
validator_assert_contains "$tmpdir/out" 'flag_value=True'
validator_assert_contains "$tmpdir/out" 'sum_n_x=45.5'
validator_assert_contains "$tmpdir/out" 'label_value=hello'
