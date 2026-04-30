#!/usr/bin/env bash
# @testcase: usage-python3-gi-shell-parse-argv-rich
# @title: PyGObject GLib.shell_parse_argv produces argv list for rich command lines
# @description: Parses a command line containing flag-value pairs, double-quoted arguments with spaces, escaped quotes, and a literal dollar token through PyGObject and verifies every argv element.
# @timeout: 180
# @tags: usage, glib, python, shell
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-shell-parse-argv-rich"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

cmdline = r'mytool --flag=value -x "quoted argument" \"escaped\" $LITERAL'
ok, argv = GLib.shell_parse_argv(cmdline)
print('ok=' + str(ok))
print('count=' + str(len(argv)))
for i, value in enumerate(argv):
    print(f'argv[{i}]={value}')
PY

validator_assert_contains "$tmpdir/out" 'ok=True'
validator_assert_contains "$tmpdir/out" 'count=6'
validator_assert_contains "$tmpdir/out" 'argv[0]=mytool'
validator_assert_contains "$tmpdir/out" 'argv[1]=--flag=value'
validator_assert_contains "$tmpdir/out" 'argv[2]=-x'
validator_assert_contains "$tmpdir/out" 'argv[3]=quoted argument'
validator_assert_contains "$tmpdir/out" 'argv[4]="escaped"'
validator_assert_contains "$tmpdir/out" 'argv[5]=$LITERAL'
