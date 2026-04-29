#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant-dict-count
# @title: PyGObject GLib variant dict
# @description: Builds a GLib VariantDict through PyGObject and verifies a typed lookup returns the inserted integer.
# @timeout: 180
# @tags: usage, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant-dict-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
dictionary = GLib.VariantDict.new(None)
dictionary.insert_value('count', GLib.Variant('i', 23))
value = dictionary.end()
lookup = value.lookup_value('count', GLib.VariantType.new('i'))
print(lookup.unpack())
PYCASE
validator_assert_contains "$tmpdir/out" '23'
