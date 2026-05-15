#!/usr/bin/env bash
# @testcase: usage-python3-gi-r19-variant-is-container-tuple-vs-int
# @title: PyGObject GLib.Variant.is_container distinguishes tuple (true) from scalar int (false)
# @description: Builds a tuple variant GLib.Variant("(si)") and a scalar int variant GLib.Variant("i") and asserts is_container returns True for the tuple and False for the int, exercising the variant container-classification predicate on a deterministic pair of types.
# @timeout: 60
# @tags: usage, python, variant, is-container, r19
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

tup = GLib.Variant("(si)", ("hi", 5))
scalar = GLib.Variant("i", 3)
print("tuple=" + str(tup.is_container()))
print("int=" + str(scalar.is_container()))
PY

validator_assert_contains "$tmpdir/out" 'tuple=True'
validator_assert_contains "$tmpdir/out" 'int=False'
