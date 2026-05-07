#!/usr/bin/env bash
# @testcase: usage-python3-gi-r12-keyfile-set-string-list
# @title: PyGObject GLib.KeyFile set_string_list serializes semicolon-terminated list
# @description: Calls KeyFile.set_string_list with a 3-element list and asserts the serialized to_data emits the canonical semicolon-separated, semicolon-terminated form.
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
kf.set_string_list("section", "items", ["alpha", "beta", "gamma"])
data, _length = kf.to_data()
print("data-start")
print(data, end="")
print("data-end")
got = kf.get_string_list("section", "items")
print("got", got)
PY

validator_assert_contains "$tmpdir/out" 'items=alpha;beta;gamma;'
validator_assert_contains "$tmpdir/out" "got ['alpha', 'beta', 'gamma']"
