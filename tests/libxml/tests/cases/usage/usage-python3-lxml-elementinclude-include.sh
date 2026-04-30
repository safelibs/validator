#!/usr/bin/env bash
# @testcase: usage-python3-lxml-elementinclude-include
# @title: lxml ElementInclude include resolution
# @description: Stages a parent XML document with an xi:include referencing a sibling fragment, resolves the include through lxml.ElementInclude.include rather than tree.xinclude(), and verifies that the included element appears in the resolved tree with its text and attributes preserved.
# @timeout: 180
# @tags: usage, xml, python, xinclude
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/main.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<root xmlns:xi="http://www.w3.org/2001/XInclude">
  <header>main</header>
  <xi:include href="fragment.xml" parse="xml"/>
</root>
XML

cat >"$tmpdir/fragment.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<included flag="on">payload-from-fragment</included>
XML

MAIN_PATH="$tmpdir/main.xml" python3 - >"$tmpdir/out" <<'PY'
import os
from lxml import etree, ElementInclude

tree = etree.parse(os.environ["MAIN_PATH"])
root = tree.getroot()

# Resolve XInclude via ElementInclude.include, not tree.xinclude().
ElementInclude.include(root)

# The xi:include element must have been replaced by <included>.
assert root.find("{http://www.w3.org/2001/XInclude}include") is None
included = root.find("included")
assert included is not None, etree.tostring(root)
assert included.text == "payload-from-fragment", repr(included.text)
assert included.get("flag") == "on", repr(included.get("flag"))

# Header element survives intact.
header = root.findtext("header")
assert header == "main", repr(header)

print("included-text=" + included.text)
print("included-flag=" + included.get("flag"))
print("header=" + header)
PY

validator_assert_contains "$tmpdir/out" 'included-text=payload-from-fragment'
validator_assert_contains "$tmpdir/out" 'included-flag=on'
validator_assert_contains "$tmpdir/out" 'header=main'
