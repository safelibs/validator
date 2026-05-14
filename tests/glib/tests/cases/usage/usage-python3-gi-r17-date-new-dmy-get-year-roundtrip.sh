#!/usr/bin/env bash
# @testcase: usage-python3-gi-r17-date-new-dmy-get-year-roundtrip
# @title: PyGObject GLib.Date.new_dmy preserves year on get_year readback
# @description: Constructs a GLib.Date via new_dmy(15, GLib.DateMonth.MAY, 2026) and asserts get_day, get_month, and get_year report the same values back, exercising the date constructor and accessor path with a distinct calendar date.
# @timeout: 60
# @tags: usage, python, date
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

d = GLib.Date.new_dmy(15, GLib.DateMonth.MAY, 2026)
print("day=" + str(d.get_day()))
print("month=" + str(int(d.get_month())))
print("year=" + str(d.get_year()))
PY

validator_assert_contains "$tmpdir/out" 'day=15'
validator_assert_contains "$tmpdir/out" 'month=5'
validator_assert_contains "$tmpdir/out" 'year=2026'
