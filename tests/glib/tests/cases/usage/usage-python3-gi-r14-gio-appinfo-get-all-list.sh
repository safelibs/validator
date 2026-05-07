#!/usr/bin/env bash
# @testcase: usage-python3-gi-r14-gio-appinfo-get-all-list
# @title: PyGObject Gio.AppInfo.get_all returns a list whose entries expose get_name
# @description: Calls Gio.AppInfo.get_all and asserts the result is a Python list (possibly empty under a minimal install) where every present entry exposes a callable get_name returning a string.
# @timeout: 60
# @tags: usage, python, gio, appinfo
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import Gio
apps = Gio.AppInfo.get_all()
print("type_is_list", isinstance(apps, list))
print("nonneg", len(apps) >= 0)
ok = True
for app in apps:
    name = app.get_name()
    if not isinstance(name, str):
        ok = False
        break
print("all_have_name", ok)
PY

validator_assert_contains "$tmpdir/out" 'type_is_list True'
validator_assert_contains "$tmpdir/out" 'nonneg True'
validator_assert_contains "$tmpdir/out" 'all_have_name True'
