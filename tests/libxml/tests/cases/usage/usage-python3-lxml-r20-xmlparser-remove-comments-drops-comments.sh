#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r20-xmlparser-remove-comments-drops-comments
# @title: lxml XMLParser remove_comments=True drops <!--..--> nodes from the parsed tree
# @description: Parses an XML document containing a comment node using etree.XMLParser(remove_comments=True), serializes back via tostring, and asserts the resulting output contains no '<!--' substring while still preserving the surrounding elements — pinning the libxml2 parser's comment-stripping path through lxml.
# @timeout: 60
# @tags: usage, xml, python, parser, comments, r20
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

parser = etree.XMLParser(remove_comments=True)
root = etree.fromstring(b'<r><a/><!--strip me--><b/></r>', parser)
print('xml=' + etree.tostring(root).decode('ascii'))
PY

grep -Fq 'xml=<r><a/><b/></r>' "$tmpdir/out" || {
    echo "expected comment to be stripped; got:" >&2
    cat "$tmpdir/out" >&2
    exit 1
}
