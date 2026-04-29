#!/usr/bin/env bash
# @testcase: usage-python3-gi-keyfile-roundtrip
# @title: PyGObject keyfile round trip
# @description: Exercises pygobject keyfile round trip through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-keyfile-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_double_schema() {
  mkdir -p "$tmpdir/schemas-double"
  cat >"$tmpdir/schemas-double/org.validator.double.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.double" path="/org/validator/double/">
    <key name="ratio" type="d">
      <default>2.5</default>
    </key>
  </schema>
</schemalist>
XML
}

write_int_array_schema() {
  mkdir -p "$tmpdir/schemas-array"
  cat >"$tmpdir/schemas-array/org.validator.int-array.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.int-array" path="/org/validator/int-array/">
    <key name="items" type="ai">
      <default>[1, 2, 3]</default>
    </key>
  </schema>
</schemalist>
XML
}

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
key = GLib.KeyFile()
key.set_string('demo', 'name', 'alpha')
key.set_integer('demo', 'count', 7)
print(key.to_data()[0])
PY
validator_assert_contains "$tmpdir/out" 'name=alpha'
validator_assert_contains "$tmpdir/out" 'count=7'
