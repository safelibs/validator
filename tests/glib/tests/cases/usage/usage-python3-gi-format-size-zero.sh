#!/usr/bin/env bash
# @testcase: usage-python3-gi-format-size-zero
# @title: PyGObject GLib format_size zero edge case
# @description: Calls GLib.format_size(0) through PyGObject and verifies the singular bytes formatting of a zero-byte input under the C locale.
# @timeout: 180
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-format-size-zero"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

print("zero=[" + GLib.format_size(0) + "]")
print("one=[" + GLib.format_size(1) + "]")
PY

validator_assert_contains "$tmpdir/out" 'zero=[0 bytes]'
validator_assert_contains "$tmpdir/out" 'one=[1 byte]'
