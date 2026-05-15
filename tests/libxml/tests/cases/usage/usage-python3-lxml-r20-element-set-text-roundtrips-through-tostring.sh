#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r20-element-set-text-roundtrips-through-tostring
# @title: lxml element.text assignment with ampersand serializes as &amp; via tostring
# @description: Creates an element, assigns text containing an ampersand (e.g. 'A & B'), serializes via etree.tostring, and asserts the resulting bytes contain '&amp;' (escaped) and not a bare '&' — pinning the libxml2 entity-escape contract through lxml's text setter.
# @timeout: 60
# @tags: usage, xml, python, escape, ampersand, r20
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree
e = etree.Element('e')
e.text = 'A & B'
blob = etree.tostring(e).decode('ascii')
print('xml=' + blob)
PY

grep -Fq 'xml=<e>A &amp; B</e>' "$tmpdir/out" || {
    echo "expected escaped ampersand serialization" >&2
    cat "$tmpdir/out" >&2
    exit 1
}
