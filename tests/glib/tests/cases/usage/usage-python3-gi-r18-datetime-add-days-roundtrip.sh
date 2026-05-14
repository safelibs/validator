#!/usr/bin/env bash
# @testcase: usage-python3-gi-r18-datetime-add-days-roundtrip
# @title: PyGObject GLib.DateTime add_days returns a timestamp seven days later
# @description: Builds a GLib.DateTime at a fixed UTC instant via new_utc, calls add_days(7), and asserts the to_unix difference between the result and the source equals exactly 7 times 86400 seconds, exercising the date arithmetic helper on a deterministic UTC anchor.
# @timeout: 60
# @tags: usage, python, datetime, add-days, r18
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

base = GLib.DateTime.new_utc(2024, 6, 1, 12, 0, 0.0)
later = base.add_days(7)
diff = later.to_unix() - base.to_unix()
print("diff=" + str(diff))
PY

validator_assert_contains "$tmpdir/out" 'diff=604800'
