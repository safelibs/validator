#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r19-tostring-xml-declaration-emitted
# @title: lxml etree.tostring with xml_declaration=True emits an <?xml version="1.0"?> prolog
# @description: Serializes a small element tree via etree.tostring with xml_declaration=True and encoding='utf-8', then asserts the resulting bytes begin with an XML declaration carrying the version and encoding attributes — pinning lxml's prolog emission contract.
# @timeout: 60
# @tags: usage, xml, python, tostring, r19
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.Element('root')
etree.SubElement(root, 'child').text = 'v'
blob = etree.tostring(root, xml_declaration=True, encoding='utf-8')
print('head=' + blob[:38].decode('ascii'))
PY

grep -Eq '^head=<\?xml version=.1\.0. encoding=.[Uu][Tt][Ff]-8.' "$tmpdir/out"
