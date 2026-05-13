#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r16-iter-tag-filter-count
# @title: lxml Element.iter(tag) yields only elements matching the supplied local-name filter
# @description: Builds a tree with interleaved <a> and <b> children, asserts list(doc.iter('a')) has length 3, list(doc.iter('b')) has length 2, and list(doc.iter()) (unfiltered) has length 6 including the root — covering the iter tag-filter contract.
# @timeout: 60
# @tags: usage, xml, python, iter
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b'<r><a>1</a><b>2</b><a>3</a><b>4</b><a>5</a></r>')
print('a_count=' + str(len(list(doc.iter('a')))))
print('b_count=' + str(len(list(doc.iter('b')))))
print('all_count=' + str(len(list(doc.iter()))))
print('a_texts=' + ','.join(e.text for e in doc.iter('a')))
PY

validator_assert_contains "$tmpdir/out" 'a_count=3'
validator_assert_contains "$tmpdir/out" 'b_count=2'
validator_assert_contains "$tmpdir/out" 'all_count=6'
validator_assert_contains "$tmpdir/out" 'a_texts=1,3,5'
