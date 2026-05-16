#!/usr/bin/env bash
# @testcase: usage-python3-gi-r21-variant-int-tuple-ii-roundtrip
# @title: PyGObject GLib.Variant '(ii)' tuple of two int32 unpacks to the same Python tuple
# @description: Builds a GLib.Variant of type '(ii)' from a Python tuple (12345, -6789) and asserts unpack returns the same two-element tuple with both elements as Python ints, exercising the int32 pair tuple Variant roundtrip distinct from the existing tuple-int-only and tuple-string-vardict tests.
# @timeout: 60
# @tags: usage, python, variant, tuple, ii, r21
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

v = GLib.Variant("(ii)", (12345, -6789))
unpacked = v.unpack()
print("type=" + type(unpacked).__name__)
print("unpacked=" + repr(unpacked))
print("first=" + str(unpacked[0]))
print("second=" + str(unpacked[1]))
PY

validator_assert_contains "$tmpdir/out" 'type=tuple'
validator_assert_contains "$tmpdir/out" 'unpacked=(12345, -6789)'
validator_assert_contains "$tmpdir/out" 'first=12345'
validator_assert_contains "$tmpdir/out" 'second=-6789'
