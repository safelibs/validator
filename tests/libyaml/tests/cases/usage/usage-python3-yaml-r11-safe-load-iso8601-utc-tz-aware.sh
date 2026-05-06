#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r11-safe-load-iso8601-utc-tz-aware
# @title: PyYAML safe_load returns tz-aware datetime for ISO 8601 timestamp ending in Z
# @description: Loads a scalar of the form 2024-01-15T12:00:00Z and confirms safe_load returns a datetime with tzinfo equal to UTC, distinguishing it from naive timestamp parsing.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, datetime
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import datetime
import yaml

ts = yaml.safe_load("ts: 2024-01-15T12:00:00Z\n")['ts']
assert isinstance(ts, datetime.datetime), type(ts)
assert ts.tzinfo is not None, 'Z suffix should produce a tz-aware datetime'
assert ts.utcoffset() == datetime.timedelta(0), ts.utcoffset()
assert ts.year == 2024 and ts.month == 1 and ts.day == 15, ts
assert ts.hour == 12 and ts.minute == 0 and ts.second == 0, ts
PY
