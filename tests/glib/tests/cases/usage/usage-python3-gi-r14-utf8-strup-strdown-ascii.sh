#!/usr/bin/env bash
# @testcase: usage-python3-gi-r14-utf8-strup-strdown-ascii
# @title: PyGObject GLib.utf8_strup and utf8_strdown invert each other for ASCII
# @description: Calls GLib.utf8_strup on 'GLib R14' to obtain the upper-case form 'GLIB R14' and GLib.utf8_strdown on the same input to obtain 'glib r14', asserting both transformations match exact expected ASCII output.
# @timeout: 60
# @tags: usage, python, utf8, case
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
s = "GLib R14"
up = GLib.utf8_strup(s, -1)
dn = GLib.utf8_strdown(s, -1)
print("up", up)
print("dn", dn)
PY

validator_assert_contains "$tmpdir/out" 'up GLIB R14'
validator_assert_contains "$tmpdir/out" 'dn glib r14'
