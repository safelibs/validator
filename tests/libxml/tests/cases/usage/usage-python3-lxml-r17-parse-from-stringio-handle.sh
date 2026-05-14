#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r17-parse-from-stringio-handle
# @title: lxml etree.parse accepts an io.BytesIO handle and yields the expected root tag
# @description: Wraps a small XML payload in an io.BytesIO, passes it to etree.parse, and asserts the resulting tree's getroot().tag is 'root' and the child <item> count matches the source — exercising lxml's file-like parser path.
# @timeout: 60
# @tags: usage, xml, python, parse, stringio
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
import io
from lxml import etree

buf = io.BytesIO(b"<root><item>a</item><item>b</item><item>c</item></root>")
tree = etree.parse(buf)
root = tree.getroot()
print('tag=' + root.tag)
print('count=' + str(len(root.findall('item'))))
PY

validator_assert_contains "$tmpdir/out" 'tag=root'
validator_assert_contains "$tmpdir/out" 'count=3'
