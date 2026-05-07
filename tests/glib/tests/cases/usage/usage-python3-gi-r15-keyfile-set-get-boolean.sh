#!/usr/bin/env bash
# @testcase: usage-python3-gi-r15-keyfile-set-get-boolean
# @title: PyGObject GLib.KeyFile set_boolean and get_boolean round-trip both true and false
# @description: Constructs a GLib.KeyFile, sets boolean keys 'enabled'=True and 'disabled'=False under group 'r15', and asserts get_boolean returns True and False respectively for each key.
# @timeout: 60
# @tags: usage, python, keyfile
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
kf = GLib.KeyFile()
kf.set_boolean("r15", "enabled", True)
kf.set_boolean("r15", "disabled", False)
print("enabled=" + str(kf.get_boolean("r15", "enabled")))
print("disabled=" + str(kf.get_boolean("r15", "disabled")))
PY

validator_assert_contains "$tmpdir/out" 'enabled=True'
validator_assert_contains "$tmpdir/out" 'disabled=False'
