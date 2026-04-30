#!/usr/bin/env bash
# @testcase: usage-python3-gi-format-size
# @title: PyGObject GLib format size
# @description: Formats a byte count with GLib.format_size through PyGObject and verifies a human-readable string.
# @timeout: 120
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-format-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
# 1.5 MB worth of bytes in SI (1_500_000)
print(GLib.format_size(1500000))
# Exact kB boundary
print(GLib.format_size(1000))
PY

# format_size uses SI (1000-based) units and the C locale renders "1.5 MB" / "1.0 kB"
validator_assert_contains "$tmpdir/out" 'MB'
validator_assert_contains "$tmpdir/out" 'kB'
