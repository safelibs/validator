#!/usr/bin/env bash
# @testcase: usage-python3-gi-spawn-command-line-sync
# @title: PyGObject GLib spawn_command_line_sync echo
# @description: Runs /bin/echo through GLib.spawn_command_line_sync from PyGObject and verifies the captured stdout, exit status, and empty stderr.
# @timeout: 180
# @tags: usage, glib, python, spawn
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-spawn-command-line-sync"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
ok, stdout, stderr, status = GLib.spawn_command_line_sync('/bin/echo glib-spawn-marker')
print(f"ok={ok}")
print(f"status={status}")
print(f"stdout={stdout.decode().rstrip()}")
print(f"stderr_len={len(stderr)}")
PY

validator_assert_contains "$tmpdir/out" 'ok=True'
validator_assert_contains "$tmpdir/out" 'status=0'
validator_assert_contains "$tmpdir/out" 'stdout=glib-spawn-marker'
validator_assert_contains "$tmpdir/out" 'stderr_len=0'
