#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r11-resolve-entities-disabled
# @title: lxml XMLParser resolve_entities=False keeps internal entity references unexpanded
# @description: Parses a doctype-with-internal-entity document using etree.XMLParser(resolve_entities=False), serializes the result, and asserts the entity reference token survives instead of being replaced with its expansion.
# @timeout: 60
# @tags: usage, xml, python, parse
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

src = b'<!DOCTYPE r [<!ENTITY foo "bar">]><r>&foo;</r>'
parser = etree.XMLParser(resolve_entities=False)
root = etree.fromstring(src, parser)
serialized = etree.tostring(root).decode('utf-8')
print('serialized=' + serialized)
print('contains_entity=' + str('&foo;' in serialized))
print('contains_bar=' + str('bar' in serialized))
PY

validator_assert_contains "$tmpdir/out" 'contains_entity=True'
validator_assert_contains "$tmpdir/out" 'contains_bar=False'
