#!/usr/bin/env bash
# @testcase: usage-python3-gi-r12-mainloop-timeout-quits
# @title: PyGObject GLib.MainLoop quits from a 50 ms timeout callback
# @description: Schedules a GLib.timeout_add callback that invokes loop.quit and asserts MainLoop.run returns after the timeout fires, with the callback observed exactly once.
# @timeout: 60
# @tags: usage, python, mainloop
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
loop = GLib.MainLoop()
state = {"calls": 0}
def on_timeout():
    state["calls"] += 1
    loop.quit()
    return False
GLib.timeout_add(50, on_timeout)
loop.run()
print("calls", state["calls"])
print("running", loop.is_running())
PY

validator_assert_contains "$tmpdir/out" 'calls 1'
validator_assert_contains "$tmpdir/out" 'running False'
