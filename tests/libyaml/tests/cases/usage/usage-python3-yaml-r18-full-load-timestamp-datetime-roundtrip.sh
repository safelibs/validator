#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r18-full-load-timestamp-datetime-roundtrip
# @title: PyYAML safe_load parses an ISO-8601 timestamp into a datetime with expected fields
# @description: Loads a YAML scalar of the form '2025-01-02T03:04:05Z' through yaml.safe_load and asserts the resulting Python datetime carries year=2025, month=1, day=2, hour=3, minute=4, second=5 — pinning the libyaml-driven implicit timestamp resolver.
# @timeout: 60
# @tags: usage, python3-yaml, timestamp, r18
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import datetime
import yaml

data = yaml.safe_load('when: 2025-01-02T03:04:05Z\n')
when = data['when']
assert isinstance(when, datetime.datetime), type(when)
assert (when.year, when.month, when.day) == (2025, 1, 2), (when.year, when.month, when.day)
assert (when.hour, when.minute, when.second) == (3, 4, 5), (when.hour, when.minute, when.second)
PY
