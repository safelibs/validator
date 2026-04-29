#!/usr/bin/env bash
# @testcase: usage-glib-compile-schemas-string-array-list
# @title: glib-compile-schemas string array
# @description: Compiles a schema with a string array key and reads the list values back through gsettings.
# @timeout: 180
# @tags: usage, gsettings, schema
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-glib-compile-schemas-string-array-list"
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

write_string_array_schema
glib-compile-schemas "$tmpdir/schemas-strarr"
GSETTINGS_SCHEMA_DIR="$tmpdir/schemas-strarr" gsettings get org.validator.strarr words >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha'
validator_assert_contains "$tmpdir/out" 'gamma'
