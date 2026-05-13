#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r16-html-fragment-fromstring-create-parent
# @title: lxml.html.fragment_fromstring with create_parent wraps mixed text and inline children under the requested tag
# @description: Calls lxml.html.fragment_fromstring on a fragment containing both text and inline elements with create_parent='section', and asserts the returned element has tag 'section', preserves the leading text content, and lists the expected child tags in source order.
# @timeout: 60
# @tags: usage, xml, python, html, fragment
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml.html import fragment_fromstring

frag = fragment_fromstring(
    'hello <b>bold</b> and <i>italic</i>',
    create_parent='section',
)
print('tag=' + frag.tag)
print('text=' + (frag.text or ''))
print('children=' + ','.join(c.tag for c in frag))
print('child_texts=' + ','.join(c.text or '' for c in frag))
PY

validator_assert_contains "$tmpdir/out" 'tag=section'
validator_assert_contains "$tmpdir/out" 'text=hello '
validator_assert_contains "$tmpdir/out" 'children=b,i'
validator_assert_contains "$tmpdir/out" 'child_texts=bold,italic'
