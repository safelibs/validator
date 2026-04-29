#!/usr/bin/env bash
# @testcase: usage-gio-info-unix-mode-attribute
# @title: gio info reports unix mode
# @description: Queries the unix::mode file attribute through gio info and verifies the attribute label appears in the output.
# @timeout: 180
# @tags: usage, gio, attributes
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-unix-mode-attribute"
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

printf 'mode payload\n' >"$tmpdir/file.txt"
chmod 0644 "$tmpdir/file.txt"
gio info -a unix::mode "$tmpdir/file.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'unix::mode:'
