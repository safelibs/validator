#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r20-strip-tags-removes-named-element
# @title: lxml etree.strip_tags removes the named element while preserving inline text
# @description: Builds a tree with mixed content '<r>a<b>middle</b>z</r>', calls etree.strip_tags(root, 'b') and asserts the serialized output is '<r>amiddlez</r>' — pinning lxml's strip_tags content-promotion behavior over libxml2's tree manipulation API.
# @timeout: 60
# @tags: usage, xml, python, strip-tags, r20
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.fromstring(b'<r>a<b>middle</b>z</r>')
etree.strip_tags(root, 'b')
print('xml=' + etree.tostring(root).decode('ascii'))
PY

grep -Fxq 'xml=<r>amiddlez</r>' "$tmpdir/out" || {
    echo "expected strip_tags to leave amiddlez" >&2
    cat "$tmpdir/out" >&2
    exit 1
}
