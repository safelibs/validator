#!/usr/bin/env bash
# @testcase: usage-python3-gi-shell-parse-argv-batch11
# @title: PyGObject GLib shell parse argv
# @description: Parses a quoted command line into argv entries with GLib through PyGObject.
# @timeout: 180
# @tags: usage, python, glib
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-shell-parse-argv-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
ok, argv = GLib.shell_parse_argv('cmd "two words"')
assert ok
print(argv[0])
print(argv[1])
PYCASE
validator_assert_contains "$tmpdir/out" 'cmd'
validator_assert_contains "$tmpdir/out" 'two words'
