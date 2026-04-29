#!/usr/bin/env bash
# @testcase: python-binding-smoke
# @title: Python libxml2 binding smoke
# @description: Parses and queries XML through the packaged Python libxml2 binding.
# @timeout: 120
# @tags: python, binding

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import libxml2
Doc = libxml2.parseDoc('<root><item>alpha</item></root>')
ctx = Doc.xpathNewContext(); items = ctx.xpathEval('//item')
print('items=%d text=%s' % (len(items), items[0].content))
ctx.xpathFreeContext(); Doc.freeDoc()
raise SystemExit(0 if len(items) == 1 else 1)
PY
