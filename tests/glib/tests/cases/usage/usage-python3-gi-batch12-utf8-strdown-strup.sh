#!/usr/bin/env bash
# @testcase: usage-python3-gi-batch12-utf8-strdown-strup
# @title: PyGObject GLib.utf8_strdown / utf8_strup roundtrip
# @description: Verifies GLib.utf8_strdown and GLib.utf8_strup correctly lowercase and uppercase ASCII and Latin-1 strings.
# @timeout: 60
# @tags: usage, python, utf8
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
src = "Hello CAFÉ"
lower = GLib.utf8_strdown(src, -1)
upper = GLib.utf8_strup(src, -1)
print(lower)
print(upper)
assert lower == "hello café"
assert upper == "HELLO CAFÉ"
PY
validator_assert_contains "$tmpdir/out" 'hello café'
validator_assert_contains "$tmpdir/out" 'HELLO CAFÉ'
