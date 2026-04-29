#!/usr/bin/env bash
# @testcase: usage-glib-compile-resources
# @title: glib resource compilation
# @description: Compiles a small GResource bundle with glib-compile-resources and verifies output bytes.
# @timeout: 180
# @tags: usage, glib, resources
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-glib-compile-resources"
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

mkdir -p "$tmpdir/res"
printf 'resource payload\n' >"$tmpdir/res/payload.txt"
cat >"$tmpdir/res/demo.gresource.xml" <<'XML'
<gresources>
  <gresource prefix="/org/validator">
    <file>payload.txt</file>
  </gresource>
</gresources>
XML
glib-compile-resources --sourcedir="$tmpdir/res" --target="$tmpdir/demo.gresource" "$tmpdir/res/demo.gresource.xml"
validator_require_file "$tmpdir/demo.gresource"
test "$(wc -c <"$tmpdir/demo.gresource")" -gt 0
