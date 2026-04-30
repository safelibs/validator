#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant-get-strv
# @title: PyGObject GLib Variant get_strv
# @description: Builds a string-array GLib.Variant and reads it back as a native string list with Variant.get_strv() through PyGObject.
# @timeout: 180
# @tags: usage, glib, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant-get-strv"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

v = GLib.Variant("as", ["alpha", "beta", "gamma"])
items = v.get_strv()
print("type=" + type(items).__name__)
print("count=" + str(len(items)))
print("first=" + items[0])
print("last=" + items[-1])
print("joined=" + ",".join(items))
PY

validator_assert_contains "$tmpdir/out" 'count=3'
validator_assert_contains "$tmpdir/out" 'first=alpha'
validator_assert_contains "$tmpdir/out" 'last=gamma'
validator_assert_contains "$tmpdir/out" 'joined=alpha,beta,gamma'
