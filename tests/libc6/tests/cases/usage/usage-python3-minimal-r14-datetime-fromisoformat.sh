#!/usr/bin/env bash
# @testcase: usage-python3-minimal-r14-datetime-fromisoformat
# @title: python3 datetime.fromisoformat parses and round-trips an ISO-8601 timestamp
# @description: Constructs a fixed UTC datetime via datetime.datetime.fromisoformat, asserts each component (year, month, day, hour, minute, second, microsecond, tzinfo offset) matches the source string, and asserts dt.isoformat() yields the same string back, exercising the libc-backed time library bindings.
# @timeout: 60
# @tags: usage, python3, datetime, libc
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from datetime import datetime, timezone, timedelta

src = "2024-03-15T12:34:56.789012+00:00"
dt = datetime.fromisoformat(src)

assert dt.year == 2024, dt.year
assert dt.month == 3, dt.month
assert dt.day == 15, dt.day
assert dt.hour == 12, dt.hour
assert dt.minute == 34, dt.minute
assert dt.second == 56, dt.second
assert dt.microsecond == 789012, dt.microsecond
assert dt.tzinfo is not None
assert dt.utcoffset() == timedelta(0), dt.utcoffset()

assert dt.isoformat() == src, dt.isoformat()
print("ok", dt.isoformat())
PY
