#!/usr/bin/env bash
# @testcase: usage-gio-cat-file
# @title: gio prints file content
# @description: Reads a local file with gio cat and verifies the emitted bytes.
# @timeout: 120
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-cat-file"
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

printf 'gio cat payload\n' >"$tmpdir/input.txt"
gio cat "$tmpdir/input.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'gio cat payload'
