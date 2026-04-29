#!/usr/bin/env bash
# @testcase: usage-gsettings-read-schema
# @title: gsettings reads custom schema
# @description: Reads a default value from a compiled custom GSettings schema.
# @timeout: 120
# @tags: usage, schema
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gsettings-read-schema"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_schema() {
  mkdir -p "$tmpdir/schemas"
  cat >"$tmpdir/schemas/org.validator.demo.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.demo" path="/org/validator/demo/">
    <key name="message" type="s">
      <default>'hello-schema'</default>
    </key>
  </schema>
</schemalist>
XML
}

write_schema
glib-compile-schemas "$tmpdir/schemas"
GSETTINGS_SCHEMA_DIR="$tmpdir/schemas" gsettings get org.validator.demo message >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'hello-schema'
