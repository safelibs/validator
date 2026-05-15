#!/usr/bin/env bash
# @testcase: usage-python3-gi-r20-keyfile-set-double-roundtrip
# @title: PyGObject GLib.KeyFile.set_double then get_double roundtrips 3.14159
# @description: Constructs a GLib.KeyFile and calls set_double on group="math" key="pi" with value 3.14159, then immediately calls get_double on the same group/key and asserts the returned float is within 1e-9 of 3.14159, exercising the typed double setter/getter pairing distinct from prior string/integer/boolean key tests.
# @timeout: 60
# @tags: usage, python, keyfile, double, r20
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

kf = GLib.KeyFile()
kf.set_double("math", "pi", 3.14159)
got = kf.get_double("math", "pi")
print("ok=" + ("yes" if abs(got - 3.14159) < 1e-9 else "no"))
print("got=" + repr(got))
PY

validator_assert_contains "$tmpdir/out" 'ok=yes'
