#!/usr/bin/env bash
# @testcase: usage-python3-gi-r14-variant-print-roundtrip
# @title: PyGObject GLib.Variant.print round-trips through GLib.Variant.parse
# @description: Builds a Variant of type '(si)' carrying ('r14', 7), prints it with print_(False) to obtain the textual format, parses the textual representation back through GLib.Variant.parse, and asserts the round-tripped Variant equals the original.
# @timeout: 60
# @tags: usage, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
v = GLib.Variant("(si)", ("r14", 7))
text = v.print_(False)
print("text", text)
parsed = GLib.Variant.parse(GLib.VariantType.new("(si)"), text, None, None)
print("equal", v.equal(parsed))
print("first", parsed.get_child_value(0).get_string())
print("second", parsed.get_child_value(1).get_int32())
PY

validator_assert_contains "$tmpdir/out" "text ('r14', 7)"
validator_assert_contains "$tmpdir/out" 'equal True'
validator_assert_contains "$tmpdir/out" 'first r14'
validator_assert_contains "$tmpdir/out" 'second 7'
