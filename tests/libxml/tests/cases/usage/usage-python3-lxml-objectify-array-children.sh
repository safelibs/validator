#!/usr/bin/env bash
# @testcase: usage-python3-lxml-objectify-array-children
# @title: lxml objectify array-like children access
# @description: Reads an XML document through lxml.objectify and verifies the array-like access pattern over repeated children, including indexed access, len() of a repeated element, and iteration order across all siblings sharing a tag.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import objectify

xml = (
    b"<root>"
    b"<item id='1'>alpha</item>"
    b"<item id='2'>beta</item>"
    b"<item id='3'>gamma</item>"
    b"</root>"
)
root = objectify.fromstring(xml)

# Repeated child element exposes array-like access.
items = root.item
assert len(items) == 3, len(items)
assert str(items[0]) == "alpha", str(items[0])
assert str(items[1]) == "beta", str(items[1])
assert str(items[2]) == "gamma", str(items[2])
assert items[0].get("id") == "1", items[0].get("id")

values = [str(it) for it in items]
ids = [it.get("id") for it in items]
assert values == ["alpha", "beta", "gamma"], values
assert ids == ["1", "2", "3"], ids

print("count=" + str(len(items)))
print("values=" + ",".join(values))
print("ids=" + ",".join(ids))
print("first=" + str(items[0]))
print("last=" + str(items[-1]))
PY

validator_assert_contains "$tmpdir/out" 'count=3'
validator_assert_contains "$tmpdir/out" 'values=alpha,beta,gamma'
validator_assert_contains "$tmpdir/out" 'ids=1,2,3'
validator_assert_contains "$tmpdir/out" 'first=alpha'
validator_assert_contains "$tmpdir/out" 'last=gamma'
