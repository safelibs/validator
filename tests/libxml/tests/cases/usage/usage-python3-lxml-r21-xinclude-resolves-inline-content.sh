#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r21-xinclude-resolves-inline-content
# @title: lxml ElementTree.xinclude() resolves a file-based xi:include into the document tree
# @description: Writes two XML files where the parent uses <xi:include href="child.xml"/>, parses and calls ElementTree.xinclude(), then asserts the resulting serialization contains the child's <c> element — pinning lxml's libxml2 XInclude resolution on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, xml, python, xinclude, r21
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/child.xml" <<'XML'
<?xml version="1.0"?>
<c>included-r21</c>
XML

cat >"$tmpdir/parent.xml" <<XML
<?xml version="1.0"?>
<root xmlns:xi="http://www.w3.org/2001/XInclude">
  <xi:include href="${tmpdir}/child.xml"/>
</root>
XML

python3 - "$tmpdir/parent.xml" <<'PY'
import sys
from lxml import etree

tree = etree.parse(sys.argv[1])
tree.xinclude()
serialized = etree.tostring(tree)
assert b'<c>included-r21</c>' in serialized, serialized
PY
