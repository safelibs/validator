#!/usr/bin/env bash
# @testcase: usage-python3-gi-r18-keyfile-set-integer-roundtrip
# @title: PyGObject GLib.KeyFile set_integer and get_integer round-trip a positive value
# @description: Builds an empty GLib.KeyFile, calls set_integer for a key in a group with the value 42, then calls get_integer on the same group and key and asserts the returned Python int equals 42, exercising the integer scalar setter and getter pair.
# @timeout: 60
# @tags: usage, python, keyfile, integer, r18
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

kf = GLib.KeyFile()
kf.set_integer("Counters", "answer", 42)
got = kf.get_integer("Counters", "answer")
print("got=" + str(got))
print("type_is_int=" + str(type(got).__name__ == "int"))
PY

validator_assert_contains "$tmpdir/out" 'got=42'
validator_assert_contains "$tmpdir/out" 'type_is_int=True'
