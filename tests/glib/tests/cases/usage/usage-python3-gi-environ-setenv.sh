#!/usr/bin/env bash
# @testcase: usage-python3-gi-environ-setenv
# @title: PyGObject GLib environ setenv unsetenv
# @description: Mutates a fresh environ list with GLib.environ_setenv and GLib.environ_unsetenv from PyGObject and verifies entries are added, overridden, and removed.
# @timeout: 180
# @tags: usage, glib, python, environ
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-environ-setenv"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

base = ['EXISTING=keep', 'OVERRIDE=old']
print(f"start_count={len(base)}")

env1 = GLib.environ_setenv(base, 'NEW_KEY', 'new-value', True)
print(f"new_value={GLib.environ_getenv(env1, 'NEW_KEY')}")
print(f"existing={GLib.environ_getenv(env1, 'EXISTING')}")

env2 = GLib.environ_setenv(env1, 'OVERRIDE', 'updated', True)
print(f"override={GLib.environ_getenv(env2, 'OVERRIDE')}")

env3 = GLib.environ_unsetenv(env2, 'EXISTING')
print(f"after_unset_existing={GLib.environ_getenv(env3, 'EXISTING')}")
print(f"after_unset_new={GLib.environ_getenv(env3, 'NEW_KEY')}")
PY

validator_assert_contains "$tmpdir/out" 'start_count=2'
validator_assert_contains "$tmpdir/out" 'new_value=new-value'
validator_assert_contains "$tmpdir/out" 'existing=keep'
validator_assert_contains "$tmpdir/out" 'override=updated'
validator_assert_contains "$tmpdir/out" 'after_unset_existing=None'
validator_assert_contains "$tmpdir/out" 'after_unset_new=new-value'
