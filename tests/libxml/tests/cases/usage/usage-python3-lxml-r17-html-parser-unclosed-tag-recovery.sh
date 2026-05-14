#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r17-html-parser-unclosed-tag-recovery
# @title: lxml HTMLParser parses a fragment with unclosed inline tags without raising
# @description: Feeds an HTML fragment with unclosed <p> tags through lxml.html.fromstring (HTMLParser), and asserts the resulting tree exposes two <p> elements with the expected text content — exercising HTML5-style recovery on malformed input.
# @timeout: 60
# @tags: usage, xml, python, html, recovery
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import html

doc = html.fromstring('<div><p>one<p>two</div>')
ps = doc.findall('.//p')
print('count=' + str(len(ps)))
print('texts=' + ','.join(p.text for p in ps))
PY

validator_assert_contains "$tmpdir/out" 'count=2'
validator_assert_contains "$tmpdir/out" 'texts=one,two'
