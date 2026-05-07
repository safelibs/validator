#!/usr/bin/env bash
# @testcase: usage-python3-gi-r13-utf8-validate-pure-ascii
# @title: PyGObject GLib.utf8_validate accepts ASCII and multibyte UTF-8 input
# @description: Calls GLib.utf8_validate on a pure-ASCII byte string and on the multibyte UTF-8 encoding of 'café', asserting the (valid, end) tuple in each case reports True with an empty end-pointer remainder.
# @timeout: 60
# @tags: usage, python, utf8, validate
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

ascii_valid, ascii_end = GLib.utf8_validate(b"hello")
print("ascii", ascii_valid)
print("ascii_end_empty", ascii_end == "")

multi_valid, multi_end = GLib.utf8_validate("café".encode("utf-8"))
print("multi", multi_valid)
print("multi_end_empty", multi_end == "")
PY

validator_assert_contains "$tmpdir/out" 'ascii True'
validator_assert_contains "$tmpdir/out" 'ascii_end_empty True'
validator_assert_contains "$tmpdir/out" 'multi True'
validator_assert_contains "$tmpdir/out" 'multi_end_empty True'
