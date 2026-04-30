#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xpathevaluator-namespaces
# @title: lxml XPathEvaluator namespace bindings
# @description: Builds an etree.XPathEvaluator with explicit namespace bindings, evaluates several namespace-prefixed expressions against a multi-namespace document, and verifies returned node counts and string values match the expected bindings.
# @timeout: 180
# @tags: usage, xml, python, xpath
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-xpathevaluator-namespaces"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.XML(b"""<root xmlns:a="urn:a" xmlns:b="urn:b">
  <a:item id="1">alpha</a:item>
  <a:item id="2">beta</a:item>
  <b:note>hello</b:note>
  <a:item id="3">gamma</a:item>
</root>""")

evaluator = etree.XPathEvaluator(doc, namespaces={"a": "urn:a", "b": "urn:b"})

a_items = evaluator("//a:item")
b_notes = evaluator("//b:note")
note_text = evaluator("string(//b:note)")
a_count = evaluator("count(//a:item)")

assert len(a_items) == 3, len(a_items)
assert len(b_notes) == 1, len(b_notes)
assert note_text == "hello", note_text
assert a_count == 3.0, a_count

print("a-items=" + str(len(a_items)))
print("b-notes=" + str(len(b_notes)))
print("note-text=" + note_text)
print("a-count=" + str(int(a_count)))
PY

validator_assert_contains "$tmpdir/out" 'a-items=3'
validator_assert_contains "$tmpdir/out" 'b-notes=1'
validator_assert_contains "$tmpdir/out" 'note-text=hello'
validator_assert_contains "$tmpdir/out" 'a-count=3'
