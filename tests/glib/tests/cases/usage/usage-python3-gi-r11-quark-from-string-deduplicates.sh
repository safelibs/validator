#!/usr/bin/env bash
# @testcase: usage-python3-gi-r11-quark-from-string-deduplicates
# @title: PyGObject GLib.quark_from_string deduplicates equal strings to the same id
# @description: Calls GLib.quark_from_string twice with the same string, once with a different string, and verifies the two equal-string calls return the same numeric quark id while the different string yields a distinct id; also verifies quark_to_string round-trips back to the original.
# @timeout: 60
# @tags: usage, python, quark
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
q1 = GLib.quark_from_string("validator-r11-alpha")
q2 = GLib.quark_from_string("validator-r11-alpha")
q3 = GLib.quark_from_string("validator-r11-beta")
print("q1-eq-q2", q1 == q2)
print("q1-ne-q3", q1 != q3)
print("q1-positive", q1 > 0)
print("roundtrip", GLib.quark_to_string(q1))
PY

validator_assert_contains "$tmpdir/out" 'q1-eq-q2 True'
validator_assert_contains "$tmpdir/out" 'q1-ne-q3 True'
validator_assert_contains "$tmpdir/out" 'q1-positive True'
validator_assert_contains "$tmpdir/out" 'roundtrip validator-r11-alpha'
