#!/usr/bin/env bash
# @testcase: usage-python3-gi-file-load-contents
# @title: PyGObject file load contents
# @description: Exercises pygobject file load contents through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-file-load-contents"
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

printf 'load contents payload\n' >"$tmpdir/input.txt"
INPUT_PATH="$tmpdir/input.txt" python3 >"$tmpdir/out" <<'PY'
import os
from gi.repository import Gio
file = Gio.File.new_for_path(os.environ['INPUT_PATH'])
_, data, _ = file.load_contents(None)
print(data.decode())
PY
validator_assert_contains "$tmpdir/out" 'load contents payload'
