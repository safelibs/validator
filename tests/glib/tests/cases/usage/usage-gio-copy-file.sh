#!/usr/bin/env bash
# @testcase: usage-gio-copy-file
# @title: gio copies local file
# @description: Copies a local file with gio copy and verifies the destination content.
# @timeout: 120
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-copy-file"
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

printf 'gio copy payload\n' >"$tmpdir/input.txt"
gio copy "$tmpdir/input.txt" "$tmpdir/output.txt"
validator_assert_contains "$tmpdir/output.txt" 'gio copy payload'
