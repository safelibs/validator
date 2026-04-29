#!/usr/bin/env bash
# @testcase: usage-glib-compile-schemas-double
# @title: glib compile schemas double default
# @description: Exercises glib compile schemas double default through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-glib-compile-schemas-double"
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

write_double_schema
glib-compile-schemas "$tmpdir/schemas-double"
GSETTINGS_SCHEMA_DIR="$tmpdir/schemas-double" gsettings get org.validator.double ratio | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2.5'
