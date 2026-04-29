#!/usr/bin/env bash
# @testcase: usage-python3-gi-idle-add
# @title: PyGObject GLib idle add
# @description: Runs a GLib idle callback through PyGObject and verifies the callback updates state before the loop exits.
# @timeout: 180
# @tags: usage, python, glib
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-idle-add"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
loop = GLib.MainLoop()
state = {'value': 0}
def run_once():
    state['value'] = 17
    loop.quit()
    return GLib.SOURCE_REMOVE
GLib.idle_add(run_once)
loop.run()
print(state['value'])
PYCASE
validator_assert_contains "$tmpdir/out" '17'
