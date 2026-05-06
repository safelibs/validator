#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r11-html-fragment-create-parent
# @title: lxml.html.fragment_fromstring with create_parent wraps multiple top-level fragments
# @description: Calls lxml.html.fragment_fromstring on two sibling HTML elements with create_parent='div' and asserts the synthetic wrapper carries the requested tag plus both children with their original text content preserved.
# @timeout: 60
# @tags: usage, xml, python, html
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import html

frag = html.fragment_fromstring("<a>x</a><b>y</b>", create_parent='div')
children = list(frag)
print('parent=' + frag.tag)
print('child_tags=' + ','.join(c.tag for c in children))
print('child_texts=' + ','.join(c.text or '' for c in children))
PY

validator_assert_contains "$tmpdir/out" 'parent=div'
validator_assert_contains "$tmpdir/out" 'child_tags=a,b'
validator_assert_contains "$tmpdir/out" 'child_texts=x,y'
