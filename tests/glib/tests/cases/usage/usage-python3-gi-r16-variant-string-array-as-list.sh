#!/usr/bin/env bash
# @testcase: usage-python3-gi-r16-variant-string-array-as-list
# @title: PyGObject GLib.Variant 'as' round-trips a Python list of strings via unpack()
# @description: Constructs GLib.Variant('as', ['alpha', 'beta', 'gamma']), asserts the type_string is 'as', that get_n_children returns 3, and that unpack() returns the original Python list, exercising the array-of-strings serialisation path.
# @timeout: 60
# @tags: usage, python, variant, array
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
v = GLib.Variant("as", ["alpha", "beta", "gamma"])
print("type=" + v.get_type_string())
# GLib.Variant on PyGObject 3.48 exposes n_children() but the deprecated
# get_n_children alias was removed; call the current name explicitly.
print("n=" + str(v.n_children()))
print("unpacked=" + ",".join(v.unpack()))
PY

validator_assert_contains "$tmpdir/out" 'type=as'
validator_assert_contains "$tmpdir/out" 'n=3'
validator_assert_contains "$tmpdir/out" 'unpacked=alpha,beta,gamma'
