#!/usr/bin/env bash
# @testcase: usage-python3-gi-date-dmy-format
# @title: PyGObject GLib Date dmy fields
# @description: Constructs a GLib.Date with new_dmy from PyGObject and verifies day, month, year, weekday, and Julian day fields.
# @timeout: 180
# @tags: usage, glib, python, date
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-date-dmy-format"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
d = GLib.Date.new_dmy(15, GLib.DateMonth.MARCH, 2024)
print(f"valid={d.valid()}")
print(f"day={d.get_day()}")
print(f"month={int(d.get_month())}")
print(f"year={d.get_year()}")
print(f"weekday={int(d.get_weekday())}")
print(f"julian={d.get_julian()}")
PY

# 2024-03-15 was a Friday. GLib.DateWeekday.FRIDAY == 5.
validator_assert_contains "$tmpdir/out" 'valid=True'
validator_assert_contains "$tmpdir/out" 'day=15'
validator_assert_contains "$tmpdir/out" 'month=3'
validator_assert_contains "$tmpdir/out" 'year=2024'
validator_assert_contains "$tmpdir/out" 'weekday=5'
