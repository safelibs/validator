#!/usr/bin/env bash
# @testcase: usage-gio-info-file
# @title: gio reports file info
# @description: Reads standard file metadata with gio info for a local fixture.
# @timeout: 120
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-file"
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

printf 'gio info payload\n' >"$tmpdir/input.txt"
gio info "$tmpdir/input.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'standard::name'
