#!/usr/bin/env bash
# @testcase: usage-python3-gi-format-size-iec-vs-si
# @title: PyGObject GLib format_size_full unit modes
# @description: Formats the same byte count with default SI units, IEC_UNITS, and LONG_FORMAT flags through GLib.format_size_full and verifies the kB, KiB, and parenthesised exact byte count renderings.
# @timeout: 120
# @tags: usage, glib, python, format
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-format-size-iec-vs-si"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

# GLib renders the unit gap as U+00A0 (NO-BREAK SPACE); normalise to ASCII so
# the assertions below can use plain literals without depending on grep
# treating U+00A0 specially.
def norm(s: str) -> str:
    return s.replace(" ", " ")

n = 2048
print("default=" + norm(GLib.format_size(n)))
print("iec=" + norm(GLib.format_size_full(n, GLib.FormatSizeFlags.IEC_UNITS)))
print("long=" + norm(GLib.format_size_full(n, GLib.FormatSizeFlags.LONG_FORMAT)))
PY

validator_assert_contains "$tmpdir/out" 'default=2.0 kB'
validator_assert_contains "$tmpdir/out" 'iec=2.0 KiB'
validator_assert_contains "$tmpdir/out" '(2048 bytes)'
