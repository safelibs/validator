#!/usr/bin/env bash
# @testcase: usage-python3-lxml-html-cssselect
# @title: lxml.html HtmlElement cssselect
# @description: Parses HTML with lxml.html and uses HtmlElement.cssselect to pick elements by tag and class, verifying the exact list of matched text content from a small fixture.
# @timeout: 120
# @tags: usage, html, python, cssselect
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-html-cssselect"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/page.html" <<'HTML'
<!doctype html>
<html><body>
  <ul id="items">
    <li class="x">one</li>
    <li class="y">two</li>
    <li class="x">three</li>
  </ul>
  <p class="x">paragraph</p>
</body></html>
HTML

python3 - "$tmpdir/page.html" <<'PY' >"$tmpdir/out"
import sys
import lxml.html
doc = lxml.html.parse(sys.argv[1]).getroot()
hits = doc.cssselect('ul#items li.x')
print("count=%d" % len(hits))
print("texts=%s" % ",".join(h.text_content() for h in hits))
all_x = doc.cssselect('.x')
print("any_x=%d" % len(all_x))
PY

validator_assert_contains "$tmpdir/out" 'count=2'
validator_assert_contains "$tmpdir/out" 'texts=one,three'
validator_assert_contains "$tmpdir/out" 'any_x=3'
