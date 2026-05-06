#!/usr/bin/env bash
# @testcase: usage-python3-gi-r11-unichar-isalpha-isdigit-isupper
# @title: PyGObject GLib.unichar_is{alpha,digit,upper} classify ASCII characters
# @description: Calls GLib.unichar_isalpha, unichar_isdigit, and unichar_isupper on representative ASCII characters and verifies the boolean results match Unicode classification (alpha for letters, digit for 0-9, upper for capitals).
# @timeout: 60
# @tags: usage, python, unicode, classification
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
print("alpha-a", GLib.unichar_isalpha('a'))
print("alpha-Z", GLib.unichar_isalpha('Z'))
print("alpha-5", GLib.unichar_isalpha('5'))
print("digit-7", GLib.unichar_isdigit('7'))
print("digit-q", GLib.unichar_isdigit('q'))
print("upper-Q", GLib.unichar_isupper('Q'))
print("upper-q", GLib.unichar_isupper('q'))
PY

validator_assert_contains "$tmpdir/out" 'alpha-a True'
validator_assert_contains "$tmpdir/out" 'alpha-Z True'
validator_assert_contains "$tmpdir/out" 'alpha-5 False'
validator_assert_contains "$tmpdir/out" 'digit-7 True'
validator_assert_contains "$tmpdir/out" 'digit-q False'
validator_assert_contains "$tmpdir/out" 'upper-Q True'
validator_assert_contains "$tmpdir/out" 'upper-q False'
