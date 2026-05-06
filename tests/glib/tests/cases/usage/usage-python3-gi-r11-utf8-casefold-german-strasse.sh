#!/usr/bin/env bash
# @testcase: usage-python3-gi-r11-utf8-casefold-german-strasse
# @title: PyGObject GLib.utf8_casefold expands German sharp s to ss
# @description: Calls GLib.utf8_casefold on the German "Straße" and "STRASSE" and verifies both fold to the same lower-case ASCII "strasse" string, demonstrating Unicode case-folding (sharp-s expansion) distinct from a simple ASCII tolower.
# @timeout: 60
# @tags: usage, python, unicode, casefold
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
mixed = GLib.utf8_casefold("Straße", -1)
upper = GLib.utf8_casefold("STRASSE", -1)
print("mixed", repr(mixed))
print("upper", repr(upper))
print("equal", mixed == upper)
print("ascii-only", all(ord(c) < 128 for c in mixed))
PY

validator_assert_contains "$tmpdir/out" "mixed 'strasse'"
validator_assert_contains "$tmpdir/out" "upper 'strasse'"
validator_assert_contains "$tmpdir/out" 'equal True'
validator_assert_contains "$tmpdir/out" 'ascii-only True'
