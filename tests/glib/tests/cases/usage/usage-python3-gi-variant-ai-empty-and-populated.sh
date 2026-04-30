#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant-ai-empty-and-populated
# @title: PyGObject GLib.Variant ai populated and empty arrays
# @description: Constructs GLib.Variant("ai", ...) for a populated and an empty integer array through PyGObject and verifies n_children, unpack, and the type signature match the construction inputs.
# @timeout: 120
# @tags: usage, python, glib, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant-ai-empty-and-populated"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

populated = GLib.Variant("ai", [1, 2, 3])
empty = GLib.Variant("ai", [])

print(f"populated_type={populated.get_type_string()}")
print(f"populated_n={populated.n_children()}")
print(f"populated_unpack={populated.unpack()}")
print(f"empty_type={empty.get_type_string()}")
print(f"empty_n={empty.n_children()}")
print(f"empty_unpack={empty.unpack()}")
PY

validator_assert_contains "$tmpdir/out" 'populated_type=ai'
validator_assert_contains "$tmpdir/out" 'populated_n=3'
validator_assert_contains "$tmpdir/out" 'populated_unpack=[1, 2, 3]'
validator_assert_contains "$tmpdir/out" 'empty_type=ai'
validator_assert_contains "$tmpdir/out" 'empty_n=0'
validator_assert_contains "$tmpdir/out" 'empty_unpack=[]'
