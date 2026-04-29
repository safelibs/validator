#!/usr/bin/env bash
# @testcase: usage-gio-content-type
# @title: gio reports content type
# @description: Queries the standard content-type attribute for a text file.
# @timeout: 120
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-content-type"
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

printf 'content type payload\n' >"$tmpdir/input.txt"
gio info -a standard::content-type "$tmpdir/input.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'text/plain'
