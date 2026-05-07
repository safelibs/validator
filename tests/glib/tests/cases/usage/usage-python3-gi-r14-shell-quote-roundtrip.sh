#!/usr/bin/env bash
# @testcase: usage-python3-gi-r14-shell-quote-roundtrip
# @title: PyGObject GLib.shell_quote escapes spaces and round-trips via shell_unquote
# @description: Calls GLib.shell_quote on the string 'r14 with spaces' and asserts the quoted output is longer than the input, then unquotes via GLib.shell_unquote and asserts the round-tripped value equals the original byte-for-byte.
# @timeout: 60
# @tags: usage, python, shell, quote
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
original = "r14 with spaces"
quoted = GLib.shell_quote(original)
print("longer", len(quoted) > len(original))
print("quoted", quoted)
roundtrip = GLib.shell_unquote(quoted)
print("equal", roundtrip == original)
print("roundtrip", roundtrip)
PY

validator_assert_contains "$tmpdir/out" 'longer True'
validator_assert_contains "$tmpdir/out" 'equal True'
validator_assert_contains "$tmpdir/out" 'roundtrip r14 with spaces'
