#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r9-c14n2-strip-comments
# @title: lxml etree.tostring c14n2 strips comments
# @description: Serialises a tree with method=c14n2 and strip_text=False, with_comments=False and asserts the resulting bytes drop the comment node.
# @timeout: 60
# @tags: usage, python3-lxml, c14n
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from lxml import etree
src = etree.fromstring(b'<root><!-- secret --><a>1</a></root>')
out = etree.tostring(src, method='c14n2', with_comments=False)
assert b'secret' not in out, out
assert b'<a>1</a>' in out, out

with_c = etree.tostring(src, method='c14n2', with_comments=True)
assert b'secret' in with_c, with_c
PY
