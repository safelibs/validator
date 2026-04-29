#!/usr/bin/env bash
# @testcase: usage-python3-gi-shell-quote-batch11
# @title: PyGObject GLib shell quote
# @description: Calls GLib shell quoting through PyGObject.
# @timeout: 180
# @tags: usage, python, glib
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-shell-quote-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(GLib.shell_quote('alpha beta'))
PYCASE
validator_assert_contains "$tmpdir/out" "'alpha beta'"
