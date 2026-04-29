#!/usr/bin/env bash
# @testcase: usage-glib-compile-schemas-string-array
# @title: glib compiles string array schema
# @description: Compiles a GSettings schema with a string-array key and verifies gsettings reads the default list.
# @timeout: 180
# @tags: usage, glib, schema
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-glib-compile-schemas-string-array"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_int_schema() {
  mkdir -p "$tmpdir/schemas-int"
  cat >"$tmpdir/schemas-int/org.validator.more-int.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.more-int" path="/org/validator/more-int/">
    <key name="count" type="i">
      <default>7</default>
    </key>
  </schema>
</schemalist>
XML
}

write_array_schema() {
  mkdir -p "$tmpdir/schemas-array"
  cat >"$tmpdir/schemas-array/org.validator.more-array.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.more-array" path="/org/validator/more-array/">
    <key name="items" type="as">
      <default>['alpha', 'beta']</default>
    </key>
  </schema>
</schemalist>
XML
}

write_array_schema
glib-compile-schemas "$tmpdir/schemas-array"
GSETTINGS_SCHEMA_DIR="$tmpdir/schemas-array" gsettings get org.validator.more-array items | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" "'alpha'"
validator_assert_contains "$tmpdir/out" "'beta'"
