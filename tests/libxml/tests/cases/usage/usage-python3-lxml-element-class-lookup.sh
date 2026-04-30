#!/usr/bin/env bash
# @testcase: usage-python3-lxml-element-class-lookup
# @title: lxml PythonElementClassLookup custom class
# @description: Registers an etree.PythonElementClassLookup subclass on an XMLParser that returns a custom Element subclass for a specific tag, parses a document with the parser, and verifies the chosen elements are instances of the custom class while siblings remain plain etree elements.
# @timeout: 180
# @tags: usage, xml, python, lookup
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-element-class-lookup"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree


class SpecialItem(etree.ElementBase):
    def describe(self):
        return "special:" + (self.text or "")


class ItemLookup(etree.PythonElementClassLookup):
    def lookup(self, document, element):
        if element.tag == "item":
            return SpecialItem
        return None


parser = etree.XMLParser()
parser.set_element_class_lookup(ItemLookup())

root = etree.fromstring(
    b"<root><item>alpha</item><note>n1</note><item>beta</item></root>",
    parser,
)

items = root.findall("item")
notes = root.findall("note")

assert len(items) == 2, len(items)
assert len(notes) == 1, len(notes)
assert all(isinstance(it, SpecialItem) for it in items), [type(it).__name__ for it in items]
assert not isinstance(notes[0], SpecialItem), type(notes[0]).__name__

descriptions = [it.describe() for it in items]
assert descriptions == ["special:alpha", "special:beta"], descriptions

print("item-count=" + str(len(items)))
print("note-count=" + str(len(notes)))
print("descriptions=" + ",".join(descriptions))
PY

validator_assert_contains "$tmpdir/out" 'item-count=2'
validator_assert_contains "$tmpdir/out" 'note-count=1'
validator_assert_contains "$tmpdir/out" 'descriptions=special:alpha,special:beta'
