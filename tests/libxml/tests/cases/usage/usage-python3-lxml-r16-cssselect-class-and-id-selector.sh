#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r16-cssselect-class-and-id-selector
# @title: lxml CSSSelector matches .class and #id selectors against parsed HTML
# @description: Parses an HTML fragment with lxml.html.fromstring, compiles a 'div.note' and a '#main' CSSSelector, and asserts each selector returns the expected element count and the matched element's text content — exercising the cssselect translation layer on top of libxml2.
# @timeout: 60
# @tags: usage, xml, python, cssselect
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import html
from lxml.cssselect import CSSSelector

doc = html.fromstring(
    '<html><body>'
    '<div id="main">Main</div>'
    '<div class="note">N1</div>'
    '<div class="note">N2</div>'
    '<div class="other">X</div>'
    '</body></html>'
)
sel_note = CSSSelector('div.note')
sel_main = CSSSelector('#main')

notes = sel_note(doc)
main = sel_main(doc)
print('notes_count=' + str(len(notes)))
print('notes_texts=' + ','.join(n.text for n in notes))
print('main_count=' + str(len(main)))
print('main_text=' + main[0].text)
PY

validator_assert_contains "$tmpdir/out" 'notes_count=2'
validator_assert_contains "$tmpdir/out" 'notes_texts=N1,N2'
validator_assert_contains "$tmpdir/out" 'main_count=1'
validator_assert_contains "$tmpdir/out" 'main_text=Main'
