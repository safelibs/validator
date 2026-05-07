#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r15-tostring-with-tail-toggle
# @title: lxml etree.tostring(with_tail=False) drops the trailing tail text of the serialized element
# @description: Parses a document where a child element carries tail text, serializes the child with etree.tostring twice (with_tail=True default and with_tail=False), and asserts the default form preserves the tail string while with_tail=False produces the element-only serialization.
# @timeout: 60
# @tags: usage, xml, python, tostring, tail
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b'<r><a>val</a>tailtext</r>')
child = doc[0]

print('default=' + etree.tostring(child, encoding='unicode'))
print('with_tail=' + etree.tostring(child, with_tail=True, encoding='unicode'))
print('no_tail=' + etree.tostring(child, with_tail=False, encoding='unicode'))
print('child_tail=' + repr(child.tail))
PY

validator_assert_contains "$tmpdir/out" 'default=<a>val</a>tailtext'
validator_assert_contains "$tmpdir/out" 'with_tail=<a>val</a>tailtext'
validator_assert_contains "$tmpdir/out" 'no_tail=<a>val</a>'
validator_assert_contains "$tmpdir/out" "child_tail='tailtext'"
