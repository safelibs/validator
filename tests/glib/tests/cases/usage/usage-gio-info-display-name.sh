#!/usr/bin/env bash
# @testcase: usage-gio-info-display-name
# @title: gio reports display name
# @description: Reads the display name attribute for a local file through gio info.
# @timeout: 180
# @tags: usage, gio, metadata
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-display-name"
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

printf 'display payload\n' >"$tmpdir/input.txt"
gio info -a standard::display-name "$tmpdir/input.txt" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'input.txt'
