#!/usr/bin/env bash
# @testcase: usage-python3-lxml-html-fromstring-body
# @title: lxml html.fromstring body access
# @description: Parses an HTML fragment with lxml.html.fromstring, accesses the implicitly-created body element via the .body attribute, and verifies the tag, child count, and selected text content of the parsed document.
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
    b"<html><head><title>t</title></head>"
    b"<body><p class='lead'>hello</p><p>world</p></body></html>"
)

# .body returns the body subelement of the parsed document.
body = doc.body
assert body.tag == "body", body.tag

paragraphs = body.findall("p")
assert len(paragraphs) == 2, len(paragraphs)
assert paragraphs[0].get("class") == "lead", paragraphs[0].get("class")
assert paragraphs[0].text == "hello", paragraphs[0].text
assert paragraphs[1].text == "world", paragraphs[1].text

# .text_content joins the text of all descendants.
joined = body.text_content().strip()
assert "hello" in joined and "world" in joined, joined

print("body-tag=" + body.tag)
print("p-count=" + str(len(paragraphs)))
print("p0=" + paragraphs[0].text)
print("p1=" + paragraphs[1].text)
print("class0=" + paragraphs[0].get("class"))
PY

validator_assert_contains "$tmpdir/out" 'body-tag=body'
validator_assert_contains "$tmpdir/out" 'p-count=2'
validator_assert_contains "$tmpdir/out" 'p0=hello'
validator_assert_contains "$tmpdir/out" 'p1=world'
validator_assert_contains "$tmpdir/out" 'class0=lead'
