#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant-int-array-batch11
# @title: PyGObject GLib int array variant
# @description: Creates and inspects a GLib integer array variant through PyGObject.
# @timeout: 180
# @tags: usage, python, glib
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant-int-array-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
value = GLib.Variant('ai', [3, 5, 8])
print(value.n_children())
print(value.get_child_value(2).get_int32())
PYCASE
validator_assert_contains "$tmpdir/out" '3'
validator_assert_contains "$tmpdir/out" '8'
