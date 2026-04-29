#!/usr/bin/env bash
# @testcase: usage-python3-gi-uuid-random-batch11
# @title: PyGObject GLib random UUID
# @description: Generates a GLib random UUID through PyGObject.
# @timeout: 180
# @tags: usage, python, glib
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-uuid-random-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
value = GLib.uuid_string_random()
assert len(value) == 36 and value.count('-') == 4
print(value)
PYCASE
test "$(wc -c <"$tmpdir/out")" -gt 30
