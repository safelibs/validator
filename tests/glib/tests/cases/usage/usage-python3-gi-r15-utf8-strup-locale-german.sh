#!/usr/bin/env bash
# @testcase: usage-python3-gi-r15-utf8-strup-locale-german
# @title: PyGObject GLib.utf8_strup uppercases an ASCII string deterministically
# @description: Calls GLib.utf8_strup against the lowercase ASCII string 'hello-r15' and asserts the result is 'HELLO-R15', confirming uppercase folding for the ASCII subset is locale-independent.
# @timeout: 60
# @tags: usage, python, utf8
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
src = "hello-r15"
result = GLib.utf8_strup(src, len(src.encode("utf-8")))
print("up=" + result)
PY

validator_assert_contains "$tmpdir/out" 'up=HELLO-R15'
