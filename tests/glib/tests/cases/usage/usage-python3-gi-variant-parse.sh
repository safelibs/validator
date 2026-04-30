#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant-parse
# @title: PyGObject GLib Variant text parse
# @description: Parses a GVariant text-format literal with GLib.Variant.parse through PyGObject and verifies the unpacked tuple.
# @timeout: 180
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant-parse"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
text = "('alpha', @i 7, [@u 1, 2, 3])"
parsed = GLib.Variant.parse(GLib.VariantType("(siau)"), text, None, None)
name, count, items = parsed.unpack()
print(f"name={name}")
print(f"count={count}")
print(f"items={','.join(str(i) for i in items)}")
print(f"type={parsed.get_type_string()}")
PY

validator_assert_contains "$tmpdir/out" 'name=alpha'
validator_assert_contains "$tmpdir/out" 'count=7'
validator_assert_contains "$tmpdir/out" 'items=1,2,3'
validator_assert_contains "$tmpdir/out" 'type=(siau)'
