#!/usr/bin/env bash
# @testcase: usage-python3-gi-keyfile-keys
# @title: PyGObject KeyFile keys
# @description: Loads a GLib KeyFile through PyGObject and verifies the declared key names can be enumerated.
# @timeout: 180
# @tags: usage, glib, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-keyfile-keys"
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

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
key = GLib.KeyFile()
data = "[demo]\nalpha=1\nbeta=2\n"
key.load_from_data(data, len(data), GLib.KeyFileFlags.NONE)
result = key.get_keys("demo")
keys = result[0] if isinstance(result, tuple) else result
print(",".join(sorted(keys)))
PY
validator_assert_contains "$tmpdir/out" 'alpha'
validator_assert_contains "$tmpdir/out" 'beta'
