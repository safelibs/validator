#!/usr/bin/env bash
# @testcase: usage-python3-lxml-c14n-exclusive
# @title: lxml C14N exclusive canonicalization
# @description: Canonicalizes XML through lxml etree.canonicalize with exclusive=True and verifies that unused namespace declarations are stripped from the canonical form while the in-scope namespace remains.
# @timeout: 120
# @tags: usage, xml, python, c14n
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-c14n-exclusive"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' >"$tmpdir/out"
from lxml import etree
xml = (
    '<root xmlns:a="urn:a" xmlns:b="urn:b" xmlns:c="urn:c">'
    '<a:item>X</a:item>'
    '</root>'
)
# lxml exposes exclusive C14N (the `exclusive` flag) via etree.tostring's
# c14n method, not via etree.canonicalize, which is the C14N 2.0 wrapper.
root = etree.fromstring(xml)
inner = root[0]
out = etree.tostring(inner, method='c14n', exclusive=True)
print(out.decode('ascii'))
PY

# Exclusive C14N: only the namespace actually visibly used (a) survives on the
# inner element; unused b/c namespaces should not appear in the canonical form.
canon=$(cat "$tmpdir/out")
[[ "$canon" == *'<a:item xmlns:a="urn:a">X</a:item>'* ]] || {
  printf 'expected exclusive C14N to retain only urn:a, got: %s\n' "$canon" >&2
  exit 1
}
[[ "$canon" != *'urn:b'* ]] || {
  printf 'unused urn:b namespace leaked into exclusive C14N: %s\n' "$canon" >&2
  exit 1
}
[[ "$canon" != *'urn:c'* ]] || {
  printf 'unused urn:c namespace leaked into exclusive C14N: %s\n' "$canon" >&2
  exit 1
}
