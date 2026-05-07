#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r14-elementtree-write-c14n
# @title: lxml ElementTree.write(method='c14n') emits canonical XML with sorted attributes
# @description: Builds a tree whose root carries attributes in non-alphabetical order, calls tree.write(file, method='c14n'), and asserts the on-disk canonicalized output reorders attributes alphabetically and omits the XML declaration, matching W3C C14N expectations.
# @timeout: 60
# @tags: usage, xml, python, c14n
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.xml" >"$tmpdir/log" <<'PY'
import sys
from lxml import etree

dst = sys.argv[1]
doc = etree.fromstring(b'<r b="2" a="1"><x z="9" m="3">leaf</x></r>')
tree = etree.ElementTree(doc)
with open(dst, 'wb') as fh:
    tree.write(fh, method='c14n')

with open(dst, 'rb') as fh:
    raw = fh.read()
print('out=' + raw.decode())
PY

validator_require_file "$tmpdir/out.xml"
validator_assert_contains "$tmpdir/log" 'out=<r a="1" b="2"><x m="3" z="9">leaf</x></r>'

# C14N must not include an XML declaration.
if grep -q '<?xml' "$tmpdir/out.xml"; then
    printf 'unexpected XML declaration in c14n output\n' >&2
    cat "$tmpdir/out.xml" >&2
    exit 1
fi
