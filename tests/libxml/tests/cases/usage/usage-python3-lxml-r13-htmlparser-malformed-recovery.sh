#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r13-htmlparser-malformed-recovery
# @title: lxml etree.HTMLParser parses missing-close-tag HTML and recovers a usable tree
# @description: Feeds malformed HTML with unclosed and reordered tags into etree.HTMLParser via etree.fromstring, asserts the parser returns a tree (no exception), the document root is <html>, the body contains the expected paragraph text, the recovered list items are present in document order, and the recovered tree includes the body element.
# @timeout: 60
# @tags: usage, xml, python, html
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

malformed = (
    b"<html><body><p>r13 paragraph"
    b"<ul><li>one<li>two<li>three</ul>"
    b"</body>"  # missing </p> and </html>
)
parser = etree.HTMLParser(recover=True)
root = etree.fromstring(malformed, parser)
print('root_tag=' + root.tag)

p_text = root.xpath('string(.//p)')
print('p_text=' + p_text.strip())

items = [li.text for li in root.iter('li')]
print('items=' + ','.join(items))

bodies = root.findall('.//body')
print('body_count=' + str(len(bodies)))

ul_count = len(root.findall('.//ul'))
print('ul_count=' + str(ul_count))
PY

validator_assert_contains "$tmpdir/out" 'root_tag=html'
validator_assert_contains "$tmpdir/out" 'p_text=r13 paragraph'
validator_assert_contains "$tmpdir/out" 'items=one,two,three'
validator_assert_contains "$tmpdir/out" 'body_count=1'
validator_assert_contains "$tmpdir/out" 'ul_count=1'
