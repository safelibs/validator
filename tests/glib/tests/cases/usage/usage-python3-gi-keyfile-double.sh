#!/usr/bin/env bash
# @testcase: usage-python3-gi-keyfile-double
# @title: PyGObject GLib KeyFile double
# @description: Stores and reads a floating-point value through GLib KeyFile from PyGObject and verifies the round-tripped number.
# @timeout: 180
# @tags: usage, python, keyfile
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-keyfile-double"
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
key = GLib.KeyFile()
key.set_double('demo', 'ratio', 1.5)
print(key.get_double('demo', 'ratio'))
PYCASE
validator_assert_contains "$tmpdir/out" '1.5'
