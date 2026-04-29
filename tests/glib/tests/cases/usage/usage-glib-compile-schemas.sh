#!/usr/bin/env bash
# @testcase: usage-glib-compile-schemas
# @title: glib-compile-schemas builds schema
# @description: Compiles a small GSettings schema into a binary schema cache.
# @timeout: 120
# @tags: usage, schema
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-glib-compile-schemas"
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
validator_require_file "$tmpdir/schemas/gschemas.compiled"
