#!/usr/bin/env bash
# @testcase: usage-python3-gi-unix-epoch-year-batch11
# @title: PyGObject GLib Unix epoch date
# @description: Formats a GLib UTC DateTime created from the Unix epoch.
# @timeout: 180
# @tags: usage, python, glib
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-unix-epoch-year-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
dt = GLib.DateTime.new_from_unix_utc(0)
print(dt.format('%Y-%m-%d'))
PYCASE
validator_assert_contains "$tmpdir/out" '1970-01-01'
