#!/usr/bin/env bash
# @testcase: usage-gio-copy-overwrite-file
# @title: gio copy overwrite file
# @description: Exercises gio copy overwrite file through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-copy-overwrite-file"
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

printf 'old\n' >"$tmpdir/out.txt"
printf 'new payload\n' >"$tmpdir/in.txt"
rm "$tmpdir/out.txt"
gio copy "$tmpdir/in.txt" "$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'new payload'
