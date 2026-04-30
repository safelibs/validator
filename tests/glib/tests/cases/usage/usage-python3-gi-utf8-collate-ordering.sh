#!/usr/bin/env bash
# @testcase: usage-python3-gi-utf8-collate-ordering
# @title: PyGObject GLib.utf8_collate orders strings consistently
# @description: Compares strings via GLib.utf8_collate through PyGObject and verifies the sign of the result for less-than, greater-than, and equal cases.
# @timeout: 180
# @tags: usage, glib, python, utf8
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-utf8-collate-ordering"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

cmp_lt = GLib.utf8_collate('apple', 'banana')
cmp_gt = GLib.utf8_collate('banana', 'apple')
cmp_eq = GLib.utf8_collate('apple', 'apple')

# Normalize to a stable sign so the test does not depend on exact magnitudes.
def sign(value):
    if value < 0:
        return 'lt'
    if value > 0:
        return 'gt'
    return 'eq'

print('apple_vs_banana=' + sign(cmp_lt))
print('banana_vs_apple=' + sign(cmp_gt))
print('apple_vs_apple=' + sign(cmp_eq))
PY

validator_assert_contains "$tmpdir/out" 'apple_vs_banana=lt'
validator_assert_contains "$tmpdir/out" 'banana_vs_apple=gt'
validator_assert_contains "$tmpdir/out" 'apple_vs_apple=eq'
