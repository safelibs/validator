#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant-lookup
# @title: PyGObject GLib variant lookup
# @description: Looks up a typed integer value inside a GLib dictionary variant through PyGObject.
# @timeout: 180
# @tags: usage, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant-lookup"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
value = GLib.Variant('a{si}', {'alpha': 1, 'beta': 2})
lookup = value.lookup_value('beta', GLib.VariantType.new('i'))
print(lookup.unpack())
PYCASE
validator_assert_contains "$tmpdir/out" '2'
