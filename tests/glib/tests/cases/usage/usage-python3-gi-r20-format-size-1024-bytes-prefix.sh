#!/usr/bin/env bash
# @testcase: usage-python3-gi-r20-format-size-1024-bytes-prefix
# @title: PyGObject GLib.format_size on 1024 emits a human string starting with "1.0"
# @description: Calls GLib.format_size with value 1024 and asserts the returned human-readable string starts with the literal prefix "1.0" (e.g. "1.0 kB" in SI mode by default), exercising the SI-prefix formatter at exactly one binary kilobyte distinct from prior zero-input and IEC-vs-SI parity tests.
# @timeout: 60
# @tags: usage, python, format-size, kilobyte, r20
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

formatted = GLib.format_size(1024)
print("formatted=" + formatted)
print("starts=" + ("yes" if formatted.startswith("1.0") else "no"))
PY

validator_assert_contains "$tmpdir/out" 'starts=yes'
