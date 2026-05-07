#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r12-xinclude-xpointer-element
# @title: lxml ElementTree.xinclude resolves a parse=xml href into the parent tree
# @description: Builds a host XML document that XIncludes an external file with parse="xml", runs ElementTree.xinclude(), and asserts the included root element is grafted into the host tree replacing the xinclude marker, with its child text content preserved.
# @timeout: 60
# @tags: usage, xml, python, xinclude
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/data.xml" <<'XML'
<?xml version="1.0"?>
<section id="s1"><title>Inserted</title></section>
XML

cat >"$tmpdir/host.xml" <<XML
<?xml version="1.0"?>
<host xmlns:xi="http://www.w3.org/2001/XInclude">
  <xi:include href="$tmpdir/data.xml" parse="xml"/>
</host>
XML

python3 - "$tmpdir/host.xml" >"$tmpdir/out" <<'PY'
import sys
from lxml import etree

tree = etree.parse(sys.argv[1])
tree.xinclude()
root = tree.getroot()
section = root.find('section')
print('has_section=' + str(section is not None))
print('section_id=' + str(section.get('id') if section is not None else ''))
print('title_text=' + str(section.findtext('title') if section is not None else ''))
PY

validator_assert_contains "$tmpdir/out" 'has_section=True'
validator_assert_contains "$tmpdir/out" 'section_id=s1'
validator_assert_contains "$tmpdir/out" 'title_text=Inserted'
