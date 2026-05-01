#!/usr/bin/env bash
# @testcase: usage-python3-gi-find-program-in-path
# @title: PyGObject GLib find_program_in_path locates sh
# @description: Calls GLib.find_program_in_path through PyGObject for /bin/sh and verifies the resolved absolute path is executable.
# @timeout: 180
# @tags: usage, python, glib
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-find-program-in-path"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
path = GLib.find_program_in_path('sh')
print('path=' + (path or ''))
print('absolute=' + str(bool(path and path.startswith('/'))))
PY

validator_assert_contains "$tmpdir/out" 'absolute=True'

resolved=$(awk -F= '/^path=/{print $2}' "$tmpdir/out")
[[ -n "$resolved" ]] || {
  printf 'expected non-empty resolved path\n' >&2
  exit 1
}
[[ -x "$resolved" ]] || {
  printf 'expected %s to be executable\n' "$resolved" >&2
  exit 1
}
