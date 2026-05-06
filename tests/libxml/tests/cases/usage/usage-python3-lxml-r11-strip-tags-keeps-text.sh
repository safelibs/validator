#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r11-strip-tags-keeps-text
# @title: lxml etree.strip_tags removes wrappers but preserves contained text
# @description: Builds a small element tree containing repeated inline wrappers, calls etree.strip_tags to remove the wrapper element name, and asserts the serialized result keeps the surrounding plus inline text concatenated and drops the inline tags.
# @timeout: 60
# @tags: usage, xml, python, manipulate
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b"<r>before<inline>x</inline>middle<inline>y</inline>after</r>")
etree.strip_tags(doc, 'inline')
text = etree.tostring(doc).decode('utf-8')
print('serialized=' + text)
print('contains_inline=' + str('<inline' in text))
PY

validator_assert_contains "$tmpdir/out" 'serialized=<r>beforexmiddleyafter</r>'
validator_assert_contains "$tmpdir/out" 'contains_inline=False'
