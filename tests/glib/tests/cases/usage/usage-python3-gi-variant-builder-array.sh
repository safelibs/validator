#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant-builder-array
# @title: PyGObject GLib VariantBuilder array
# @description: Builds a string array with GLib VariantBuilder and unpacks the members through PyGObject.
# @timeout: 180
# @tags: usage, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant-builder-array"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
builder = GLib.VariantBuilder.new(GLib.VariantType.new('as'))
builder.add_value(GLib.Variant('s', 'alpha'))
builder.add_value(GLib.Variant('s', 'beta'))
value = builder.end()
print(','.join(value.unpack()))
PYCASE
validator_assert_contains "$tmpdir/out" 'alpha,beta'
