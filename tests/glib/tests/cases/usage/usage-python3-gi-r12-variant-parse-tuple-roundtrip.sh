#!/usr/bin/env bash
# @testcase: usage-python3-gi-r12-variant-parse-tuple-roundtrip
# @title: PyGObject GLib.Variant.parse round-trips a (sis) tuple via print/parse
# @description: Builds a Variant with signature (sis), prints it, parses the printed text back with GLib.Variant.parse, and asserts the recovered tuple components match.
# @timeout: 60
# @tags: usage, python, variant, parse
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
v = GLib.Variant("(sis)", ("alpha", -7, "beta"))
text = v.print_(True)
back = GLib.Variant.parse(GLib.VariantType.new("(sis)"), text, None, None)
got = back.unpack()
print("type", back.get_type_string())
print("got", got)
print("equal", got == ("alpha", -7, "beta"))
PY

validator_assert_contains "$tmpdir/out" 'type (sis)'
validator_assert_contains "$tmpdir/out" "got ('alpha', -7, 'beta')"
validator_assert_contains "$tmpdir/out" 'equal True'
