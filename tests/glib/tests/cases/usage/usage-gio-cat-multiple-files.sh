#!/usr/bin/env bash
# @testcase: usage-gio-cat-multiple-files
# @title: gio cat concatenates files
# @description: Concatenates two text files with gio cat and verifies both file contents appear in the merged output.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-cat-multiple-files"
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

printf 'first half\n' >"$tmpdir/a.txt"
printf 'second half\n' >"$tmpdir/b.txt"
gio cat "$tmpdir/a.txt" "$tmpdir/b.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'first half'
validator_assert_contains "$tmpdir/out" 'second half'
