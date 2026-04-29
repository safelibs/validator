#!/usr/bin/env bash
# @testcase: usage-python3-gi-file-query-exists
# @title: PyGObject file exists query
# @description: Uses Gio.File through PyGObject to query whether a local path exists and verifies the boolean result.
# @timeout: 180
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-file-query-exists"
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

printf 'exists payload\n' >"$tmpdir/input.txt"
INPUT_PATH="$tmpdir/input.txt" python3 >"$tmpdir/out" <<'PY'
import os
from gi.repository import Gio
file = Gio.File.new_for_path(os.environ["INPUT_PATH"])
print(file.query_exists(None))
PY
validator_assert_contains "$tmpdir/out" 'True'
