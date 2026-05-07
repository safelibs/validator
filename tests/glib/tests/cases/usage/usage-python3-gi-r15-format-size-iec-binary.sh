#!/usr/bin/env bash
# @testcase: usage-python3-gi-r15-format-size-iec-binary
# @title: PyGObject GLib.format_size_full with IEC_UNITS produces a MiB-suffixed binary representation
# @description: Calls GLib.format_size_full(1048576, GLib.FormatSizeFlags.IEC_UNITS) and asserts the formatted string contains 'MiB' (binary IEC prefix), distinguishing it from the SI 'MB' default representation.
# @timeout: 60
# @tags: usage, python, format-size
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
iec = GLib.format_size_full(1048576, GLib.FormatSizeFlags.IEC_UNITS)
default = GLib.format_size_full(1048576, GLib.FormatSizeFlags.DEFAULT)
print("iec=" + iec)
print("default=" + default)
print("iec_has_MiB=" + str("MiB" in iec))
print("default_has_MB=" + str("MB" in default))
PY

validator_assert_contains "$tmpdir/out" 'iec_has_MiB=True'
validator_assert_contains "$tmpdir/out" 'default_has_MB=True'
