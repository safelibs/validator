#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant-array-strings
# @title: PyGObject GLib string array variant
# @description: Builds a GLib string array variant through PyGObject and verifies child count and an indexed string element.
# @timeout: 180
# @tags: usage, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant-array-strings"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_string_array_schema() {
  mkdir -p "$tmpdir/schemas-strarr"
  cat >"$tmpdir/schemas-strarr/org.validator.strarr.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.strarr" path="/org/validator/strarr/">
    <key name="words" type="as">
      <default>['alpha','beta','gamma']</default>
    </key>
  </schema>
</schemalist>
XML
}

write_enum_schema() {
  mkdir -p "$tmpdir/schemas-uint"
  cat >"$tmpdir/schemas-uint/org.validator.uint.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.uint" path="/org/validator/uint/">
    <key name="threshold" type="u">
      <default>42</default>
    </key>
  </schema>
</schemalist>
XML
}

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
value = GLib.Variant('as', ['alpha', 'beta', 'gamma'])
print(value.n_children())
print(value.get_child_value(1).get_string())
PYCASE
validator_assert_contains "$tmpdir/out" '3'
validator_assert_contains "$tmpdir/out" 'beta'
