#!/usr/bin/env bash
# @testcase: usage-python3-lxml-html-fromstring-head
# @title: lxml html.fromstring head access
# @description: Parses an HTML document with lxml.html.fromstring, accesses the .head attribute on the resulting document, and verifies the head's tag name, child element tags, and the title text content extracted via the head subelement.
# @timeout: 180
# @tags: usage, xml, python, html
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import html

doc = html.fromstring(
    b"<html><head><title>Hello</title>"
    b"<meta charset='utf-8'/>"
    b"<link rel='stylesheet' href='a.css'/></head>"
    b"<body><p>body</p></body></html>"
)

head = doc.head
assert head.tag == "head", head.tag

children = [c.tag for c in head]
# title, meta, link in document order.
assert children == ["title", "meta", "link"], children

title = head.find("title")
assert title is not None and title.text == "Hello", title.text if title is not None else None

link = head.find("link")
assert link is not None and link.get("rel") == "stylesheet", link.get("rel") if link is not None else None
assert link.get("href") == "a.css", link.get("href")

print("head-tag=" + head.tag)
print("children=" + ",".join(children))
print("title=" + title.text)
print("link-href=" + link.get("href"))
PY

validator_assert_contains "$tmpdir/out" 'head-tag=head'
validator_assert_contains "$tmpdir/out" 'children=title,meta,link'
validator_assert_contains "$tmpdir/out" 'title=Hello'
validator_assert_contains "$tmpdir/out" 'link-href=a.css'
