#!/usr/bin/env bash
# @testcase: usage-python3-gi-path-basename-batch11
# @title: PyGObject GLib basename
# @description: Calls GLib path basename handling through PyGObject.
# @timeout: 180
# @tags: usage, python, glib
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-path-basename-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(GLib.path_get_basename('/tmp/validator/file.txt'))
PYCASE
validator_assert_contains "$tmpdir/out" 'file.txt'
