#!/usr/bin/env bash
# @testcase: usage-python3-gi-r17-variant-tuple-si-parse-print-roundtrip
# @title: PyGObject GLib.Variant.new_tuple round-trips through print/parse with type (si)
# @description: Constructs a GLib.Variant of type (si) holding ("r17", 42), prints it via print_(False), parses it back via GLib.Variant.parse and asserts the recovered tuple matches the original via get_string and get_int32, exercising the textual print/parse pair on a heterogeneous tuple.
# @timeout: 60
# @tags: usage, python, variant, tuple
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

s = GLib.Variant("s", "r17")
i = GLib.Variant("i", 42)
t = GLib.Variant.new_tuple(s, i)
text = t.print_(False)
print("text=" + text)
parsed = GLib.Variant.parse(GLib.VariantType.new("(si)"), text, None, None)
print("type=" + parsed.get_type_string())
print("str=" + parsed.get_child_value(0).get_string())
print("int=" + str(parsed.get_child_value(1).get_int32()))
PY

validator_assert_contains "$tmpdir/out" 'type=(si)'
validator_assert_contains "$tmpdir/out" 'str=r17'
validator_assert_contains "$tmpdir/out" 'int=42'
