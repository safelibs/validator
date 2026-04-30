#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant-print-compact
# @title: PyGObject GLib Variant compact print form
# @description: Prints a GLib Variant in compact form via Variant.print_(False) from PyGObject and verifies the type-annotation-free representation.
# @timeout: 180
# @tags: usage, glib, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant-print-compact"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
v = GLib.Variant("(si)", ("alpha", 7))
text = v.print_(False)
print("compact=" + text)
roundtrip = GLib.Variant.parse(None, text, None, None)
print("roundtrip=" + str(roundtrip.unpack()))
PY

validator_assert_contains "$tmpdir/out" "compact=('alpha', 7)"
validator_assert_contains "$tmpdir/out" "roundtrip=('alpha', 7)"
