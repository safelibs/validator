#!/usr/bin/env bash
# @testcase: usage-python3-gi-user-data-dir
# @title: PyGObject GLib user data dir
# @description: Reads the XDG user data directory through GLib.get_user_data_dir and verifies it honors XDG_DATA_HOME.
# @timeout: 120
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-user-data-dir"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/xdg-data"
XDG_DATA_HOME="$tmpdir/xdg-data" python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
print("user_data=" + GLib.get_user_data_dir())
print("user_config=" + GLib.get_user_config_dir())
PY

validator_assert_contains "$tmpdir/out" "user_data=$tmpdir/xdg-data"
validator_assert_contains "$tmpdir/out" 'user_config='
