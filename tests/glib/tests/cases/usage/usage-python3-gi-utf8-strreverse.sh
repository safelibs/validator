#!/usr/bin/env bash
# @testcase: usage-python3-gi-utf8-strreverse
# @title: PyGObject GLib utf8_strreverse and strlen
# @description: Reverses an ASCII string and counts a multibyte UTF-8 string with GLib.utf8_strreverse and GLib.utf8_strlen, confirming the codepoint count for caf and the reversal of hello.
# @timeout: 120
# @tags: usage, glib, python, utf8
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-utf8-strreverse"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

print("rev=" + GLib.utf8_strreverse("hello", -1))
print("len_cafe=" + str(GLib.utf8_strlen("café", -1)))
print("len_ascii=" + str(GLib.utf8_strlen("hello", -1)))
print("strup=" + GLib.utf8_strup("Café", -1))
PY

validator_assert_contains "$tmpdir/out" 'rev=olleh'
validator_assert_contains "$tmpdir/out" 'len_cafe=4'
validator_assert_contains "$tmpdir/out" 'len_ascii=5'
validator_assert_contains "$tmpdir/out" 'strup=CAF'
