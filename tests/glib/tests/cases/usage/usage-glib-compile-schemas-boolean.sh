#!/usr/bin/env bash
# @testcase: usage-glib-compile-schemas-boolean
# @title: gsettings boolean schema
# @description: Compiles a schema with a boolean key and reads it through gsettings.
# @timeout: 180
# @tags: usage, glib, schema
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-glib-compile-schemas-boolean"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_bool_schema() {
  mkdir -p "$tmpdir/schemas"
  cat >"$tmpdir/schemas/org.validator.extra.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.extra" path="/org/validator/extra/">
    <key name="enabled" type="b">
      <default>true</default>
    </key>
  </schema>
</schemalist>
XML
}

write_string_schema() {
  mkdir -p "$tmpdir/schemas-string"
  cat >"$tmpdir/schemas-string/org.validator.extra-string.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.extra-string" path="/org/validator/extra-string/">
    <key name="label" type="s">
      <default>'alpha'</default>
    </key>
  </schema>
</schemalist>
XML
}

write_bool_schema
glib-compile-schemas "$tmpdir/schemas"
GSETTINGS_SCHEMA_DIR="$tmpdir/schemas" gsettings get org.validator.extra enabled | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'true'
