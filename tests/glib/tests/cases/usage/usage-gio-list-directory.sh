#!/usr/bin/env bash
# @testcase: usage-gio-list-directory
# @title: gio lists directory children
# @description: Lists a temporary directory with gio and checks expected child names.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-list-directory"
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

mkdir -p "$tmpdir/tree"
printf 'alpha\n' >"$tmpdir/tree/alpha.txt"
printf 'beta\n' >"$tmpdir/tree/beta.txt"
gio list "$tmpdir/tree" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha.txt'
validator_assert_contains "$tmpdir/out" 'beta.txt'
