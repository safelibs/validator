#!/usr/bin/env bash
# @testcase: usage-python3-gi-datetime-iso-string
# @title: PyGObject GLib DateTime ISO 8601
# @description: Builds a UTC GLib DateTime through PyGObject and verifies the ISO 8601 format string.
# @timeout: 180
# @tags: usage, python, datetime
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-datetime-iso-string"
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

python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
dt = GLib.DateTime.new_utc(2024, 6, 1, 12, 30, 45)
print(dt.format_iso8601())
PYCASE
validator_assert_contains "$tmpdir/out" '2024-06-01T12:30:45Z'
