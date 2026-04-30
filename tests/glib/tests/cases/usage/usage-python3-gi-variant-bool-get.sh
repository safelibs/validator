#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant-bool-get
# @title: PyGObject GLib Variant boolean get_boolean
# @description: Constructs a boolean GLib Variant in PyGObject and verifies get_boolean returns True for a true-valued variant and False for a false-valued one.
# @timeout: 180
# @tags: usage, glib, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant-bool-get"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
v_true = GLib.Variant("b", True)
v_false = GLib.Variant("b", False)
print("true=" + str(v_true.get_boolean()))
print("false=" + str(v_false.get_boolean()))
print("type=" + v_true.get_type_string())
PY

validator_assert_contains "$tmpdir/out" 'true=True'
validator_assert_contains "$tmpdir/out" 'false=False'
validator_assert_contains "$tmpdir/out" 'type=b'
