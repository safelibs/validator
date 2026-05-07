#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r15-iterancestors-tag-filter
# @title: lxml Element.iterancestors yields the parent chain in walk-up order and accepts a tag filter
# @description: Walks a deeply nested document and asserts iterancestors() with no argument yields tags in inner-to-outer order, while iterancestors('b') only yields the ancestors whose tag equals "b". Pins the lxml ancestor traversal contract used by selector libraries.
# @timeout: 60
# @tags: usage, xml, python, iterancestors
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b'<a><b><c><b><d/></b></c></b></a>')
d = doc.find('.//d')
print('all=' + ','.join(el.tag for el in d.iterancestors()))
print('only_b=' + ','.join(el.tag for el in d.iterancestors('b')))
print('only_a=' + ','.join(el.tag for el in d.iterancestors('a')))
print('count_all=' + str(sum(1 for _ in d.iterancestors())))
PY

validator_assert_contains "$tmpdir/out" 'all=b,c,b,a'
validator_assert_contains "$tmpdir/out" 'only_b=b,b'
validator_assert_contains "$tmpdir/out" 'only_a=a'
validator_assert_contains "$tmpdir/out" 'count_all=4'
