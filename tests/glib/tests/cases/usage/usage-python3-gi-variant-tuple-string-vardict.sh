#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant-tuple-string-vardict
# @title: PyGObject GLib Variant composite tuple with vardict
# @description: Builds a GLib.Variant with the (sa{sv}) signature combining a string and a string-keyed variant dict and verifies the unpacked Python representation.
# @timeout: 180
# @tags: usage, glib, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant-tuple-string-vardict"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

v = GLib.Variant("(sa{sv})", ("name", {"k": GLib.Variant("s", "v")}))
print("signature=" + v.get_type_string())

label, mapping = v.unpack()
print("label=" + label)
print("key=k value=" + mapping["k"])
print("count=" + str(len(mapping)))
PY

validator_assert_contains "$tmpdir/out" 'signature=(sa{sv})'
validator_assert_contains "$tmpdir/out" 'label=name'
validator_assert_contains "$tmpdir/out" 'key=k value=v'
validator_assert_contains "$tmpdir/out" 'count=1'
