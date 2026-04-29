#!/usr/bin/env bash
# @testcase: usage-python3-lxml-comment-node
# @title: lxml comment node
# @description: Creates an XML comment node through lxml and verifies the serialized output preserves the comment text.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-comment-node"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.Element("root")
root.append(etree.Comment("note"))
print(etree.tostring(root).decode())
PY
validator_assert_contains "$tmpdir/out" '<!--note-->'
