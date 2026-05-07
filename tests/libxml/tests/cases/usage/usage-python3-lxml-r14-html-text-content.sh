#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r14-html-text-content
# @title: lxml.html.fromstring().text_content() flattens nested element text into a single string
# @description: Parses an HTML fragment with nested inline elements via lxml.html.fromstring, calls .text_content() on the root, and asserts the returned string is the concatenation of every descendant text node in document order with no element markup remaining.
# @timeout: 60
# @tags: usage, xml, python, html, text-content
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import html

doc = html.fromstring(
    '<div><p>Hello <b>brave</b> <i>new</i> world</p>'
    '<p>Goodbye<span>!</span></p></div>'
)
text = doc.text_content()
print('text=' + text)
print('has_tag=' + str('<' in text))
print('contains_brave=' + str('brave' in text))
print('contains_goodbye=' + str('Goodbye!' in text))
PY

validator_assert_contains "$tmpdir/out" 'text=Hello brave new worldGoodbye!'
validator_assert_contains "$tmpdir/out" 'has_tag=False'
validator_assert_contains "$tmpdir/out" 'contains_brave=True'
validator_assert_contains "$tmpdir/out" 'contains_goodbye=True'
