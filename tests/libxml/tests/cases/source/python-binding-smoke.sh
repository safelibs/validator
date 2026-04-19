#!/usr/bin/env bash
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
