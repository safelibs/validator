#!/usr/bin/env bash
# @testcase: usage-python3-gi-keyfile-integer-list
# @title: PyGObject GLib KeyFile integer list
# @description: Stores and reads an integer list through GLib KeyFile in PyGObject.
# @timeout: 180
# @tags: usage, python, keyfile
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-keyfile-integer-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
key = GLib.KeyFile()
key.set_integer_list('demo', 'values', [2, 4, 6])
print(','.join(str(value) for value in key.get_integer_list('demo', 'values')))
PYCASE
validator_assert_contains "$tmpdir/out" '2,4,6'
