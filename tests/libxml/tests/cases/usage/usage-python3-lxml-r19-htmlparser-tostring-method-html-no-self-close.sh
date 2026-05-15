#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r19-htmlparser-tostring-method-html-no-self-close
# @title: lxml etree.tostring with method=html emits non-void elements with explicit close tags
# @description: Parses a small HTML fragment via lxml.html.fromstring, serializes the tree with etree.tostring(method='html'), and asserts a non-void element like <p></p> is rendered with an explicit closing tag rather than a self-closing form — pinning libxml2's HTML serializer behavior.
# @timeout: 60
# @tags: usage, xml, python, html, tostring, r19
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree, html
root = html.fromstring('<div><p></p></div>')
blob = etree.tostring(root, method='html').decode('ascii')
print('html=' + blob)
PY

grep -Fq '<p></p>' "$tmpdir/out"
# And NOT a self-closing <p/> form.
if grep -Eq '<p[ /]*/>' "$tmpdir/out"; then
    echo "expected <p></p> non-self-closing form in HTML serialization" >&2
    cat "$tmpdir/out" >&2
    exit 1
fi
