#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r10-tostring-text-method
# @title: lxml etree.tostring with method='text' returns concatenated text
# @description: Builds a small element tree with mixed text and tail content, serializes it with method='text', and asserts that markup is stripped and only the concatenated character data remains.
# @timeout: 60
# @tags: usage, xml, python, serialize
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(
    b"<doc>alpha<child>beta</child>gamma<child>delta</child>epsilon</doc>"
)
text_bytes = etree.tostring(doc, method='text', encoding='utf-8')
print('text=' + text_bytes.decode('utf-8'))
print('contains_lt=' + str('<' in text_bytes.decode('utf-8')))
PY

validator_assert_contains "$tmpdir/out" 'text=alphabetagammadeltaepsilon'
validator_assert_contains "$tmpdir/out" 'contains_lt=False'
