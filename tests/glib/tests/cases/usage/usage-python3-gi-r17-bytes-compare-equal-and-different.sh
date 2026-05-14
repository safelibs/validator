#!/usr/bin/env bash
# @testcase: usage-python3-gi-r17-bytes-compare-equal-and-different
# @title: PyGObject GLib.Bytes.compare returns zero for equal and non-zero for different buffers
# @description: Builds two GLib.Bytes objects with identical 8-byte payloads plus one with a different payload, calls GLib.Bytes.compare across the pairs, and asserts the same-payload comparison returns 0 while the different-payload comparison returns a non-zero integer, exercising the GLib.Bytes byte-wise comparator.
# @timeout: 60
# @tags: usage, python, bytes, compare
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

a = GLib.Bytes.new(bytes([0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88]))
b = GLib.Bytes.new(bytes([0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88]))
c = GLib.Bytes.new(bytes([0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00, 0x11]))

eq = a.compare(b)
df = a.compare(c)
print("eq=" + str(eq))
print("df_nonzero=" + str(df != 0))
PY

validator_assert_contains "$tmpdir/out" 'eq=0'
validator_assert_contains "$tmpdir/out" 'df_nonzero=True'
