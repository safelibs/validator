#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r11-strip-elements-no-tail
# @title: lxml etree.strip_elements drops subtree but with_tail=False preserves between-text
# @description: Calls etree.strip_elements with with_tail=False to remove a repeated child element while keeping the surrounding character data and inter-element text intact, asserting the resulting serialized form.
# @timeout: 60
# @tags: usage, xml, python, manipulate
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b"<r><a>1</a>between<a>2</a>tail</r>")
etree.strip_elements(doc, 'a', with_tail=False)
print('serialized=' + etree.tostring(doc).decode('utf-8'))
print('a_count=' + str(len(doc.findall('a'))))
PY

validator_assert_contains "$tmpdir/out" 'serialized=<r>betweentail</r>'
validator_assert_contains "$tmpdir/out" 'a_count=0'
