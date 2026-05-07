#!/usr/bin/env bash
# @testcase: usage-python3-gi-r12-datetime-format-utc-iso
# @title: PyGObject GLib.DateTime new_utc formats a fixed UTC timestamp via format
# @description: Constructs GLib.DateTime.new_utc(2024,3,14,15,9,26.535) and asserts format("%Y-%m-%dT%H:%M:%S") returns the expected ISO-style string.
# @timeout: 60
# @tags: usage, python, datetime
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
dt = GLib.DateTime.new_utc(2024, 3, 14, 15, 9, 26.535)
print("formatted", dt.format("%Y-%m-%dT%H:%M:%S"))
print("year", dt.get_year())
print("month", dt.get_month())
print("day", dt.get_day_of_month())
print("hour", dt.get_hour())
print("minute", dt.get_minute())
print("second", dt.get_second())
PY

validator_assert_contains "$tmpdir/out" 'formatted 2024-03-14T15:09:26'
validator_assert_contains "$tmpdir/out" 'year 2024'
validator_assert_contains "$tmpdir/out" 'month 3'
validator_assert_contains "$tmpdir/out" 'day 14'
validator_assert_contains "$tmpdir/out" 'hour 15'
validator_assert_contains "$tmpdir/out" 'minute 9'
validator_assert_contains "$tmpdir/out" 'second 26'
