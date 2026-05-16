#!/usr/bin/env bash
# @testcase: usage-python3-gi-r21-spawn-command-line-sync-true-exit-zero
# @title: PyGObject GLib.spawn_command_line_sync('/bin/true') returns success and exit status zero
# @description: Calls GLib.spawn_command_line_sync('/bin/true') and asserts the tuple returns success True with empty stdout/stderr bytes and exit status equal to 0, exercising the spawn-sync wrapper return-value shape on a known-success command distinct from the existing spawn-command-line-sync test that only verified stdout payload.
# @timeout: 60
# @tags: usage, python, spawn, r21
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

ok, out, err, status = GLib.spawn_command_line_sync("/bin/true")
print("ok=" + repr(ok))
print("out_len=" + str(len(out)))
print("err_len=" + str(len(err)))
print("status=" + str(status))
PY

validator_assert_contains "$tmpdir/out" 'ok=True'
validator_assert_contains "$tmpdir/out" 'out_len=0'
validator_assert_contains "$tmpdir/out" 'err_len=0'
validator_assert_contains "$tmpdir/out" 'status=0'
