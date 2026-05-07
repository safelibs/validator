#!/usr/bin/env bash
# @testcase: usage-python3-gi-r15-variant-int64-bounds
# @title: PyGObject GLib.Variant 'x' carries int64 values at signed 64-bit boundaries
# @description: Builds GLib.Variant('x', value) for both INT64_MIN and INT64_MAX, asserts get_int64 returns the requested value at each boundary, and verifies type_string is 'x'.
# @timeout: 60
# @tags: usage, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
INT64_MAX = (1 << 63) - 1
INT64_MIN = -(1 << 63)
vmax = GLib.Variant("x", INT64_MAX)
vmin = GLib.Variant("x", INT64_MIN)
print("type=" + vmax.get_type_string())
print("max=" + str(vmax.get_int64()))
print("min=" + str(vmin.get_int64()))
PY

validator_assert_contains "$tmpdir/out" 'type=x'
validator_assert_contains "$tmpdir/out" 'max=9223372036854775807'
validator_assert_contains "$tmpdir/out" 'min=-9223372036854775808'
