#!/usr/bin/env bash
# @testcase: usage-python3-gi-r11-monotonic-time-delta-after-sleep
# @title: PyGObject GLib.get_monotonic_time delta exceeds elapsed sleep
# @description: Captures GLib.get_monotonic_time before and after a 100 ms time.sleep, and verifies the microsecond delta is at least 100000 us and less than 5_000_000 us, demonstrating the monotonic clock advances and is independent of wall-clock changes.
# @timeout: 60
# @tags: usage, python, time, monotonic
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
import time
from gi.repository import GLib
a = GLib.get_monotonic_time()
time.sleep(0.1)
b = GLib.get_monotonic_time()
delta = b - a
print("type", type(a).__name__)
print("delta-ge-100ms", delta >= 100000)
print("delta-lt-5s", delta < 5_000_000)
PY

validator_assert_contains "$tmpdir/out" 'type int'
validator_assert_contains "$tmpdir/out" 'delta-ge-100ms True'
validator_assert_contains "$tmpdir/out" 'delta-lt-5s True'
