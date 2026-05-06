#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r10-html-iterlinks-href-src
# @title: lxml.html.iterlinks enumerates href and src URLs
# @description: Parses an HTML fragment with anchor and image tags, walks lxml.html.iterlinks() and asserts both the href URL on the <a> tag and the src URL on the <img> tag are reported with their attribute names.
# @timeout: 60
# @tags: usage, xml, python, html
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
import lxml.html

src = (
    '<div>'
    '<a href="https://example.org/page">link</a>'
    '<img src="https://example.org/pic.png" alt="x"/>'
    '</div>'
)
fragment = lxml.html.fromstring(src)
seen = sorted(
    (el.tag, attr, url)
    for el, attr, url, _pos in fragment.iterlinks()
)
for entry in seen:
    print('link=' + ','.join(entry))
PY

validator_assert_contains "$tmpdir/out" 'link=a,href,https://example.org/page'
validator_assert_contains "$tmpdir/out" 'link=img,src,https://example.org/pic.png'
