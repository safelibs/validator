#!/usr/bin/env bash
# @testcase: usage-python3-gi-r10-shell-unquote
# @title: PyGObject GLib.shell_unquote inverts shell_quote
# @description: Quotes a string containing whitespace and a single quote with GLib.shell_quote, unquotes it with GLib.shell_unquote, and verifies the round-tripped value matches the original.
# @timeout: 60
# @tags: usage, python, shell
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
original = "hello world's friend"
quoted = GLib.shell_quote(original)
roundtrip = GLib.shell_unquote(quoted)
print("quoted-len", len(quoted) > len(original))
print("roundtrip", roundtrip)
assert quoted != original
assert roundtrip == original
PY
validator_assert_contains "$tmpdir/out" 'quoted-len True'
validator_assert_contains "$tmpdir/out" "roundtrip hello world's friend"
