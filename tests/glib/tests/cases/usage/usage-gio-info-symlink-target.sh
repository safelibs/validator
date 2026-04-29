#!/usr/bin/env bash
# @testcase: usage-gio-info-symlink-target
# @title: gio reports symlink target
# @description: Queries gio file metadata for a symbolic link and verifies the target path is reported.
# @timeout: 180
# @tags: usage, gio, metadata
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-symlink-target"
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

printf 'target payload\n' >"$tmpdir/target.txt"
ln -s "$tmpdir/target.txt" "$tmpdir/link.txt"
gio info -a standard::symlink-target "$tmpdir/link.txt" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'target.txt'
