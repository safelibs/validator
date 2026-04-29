#!/usr/bin/env bash
# @testcase: usage-python3-gi-keyfile
# @title: PyGObject GLib KeyFile
# @description: Reads an INI-style value with GLib KeyFile through PyGObject.
# @timeout: 120
# @tags: usage, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-keyfile"
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

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
key = GLib.KeyFile()
data = "[demo]\nmessage=hello-keyfile\n"
key.load_from_data(data, len(data), GLib.KeyFileFlags.NONE)
print(key.get_string("demo", "message"))
PY
validator_assert_contains "$tmpdir/out" 'hello-keyfile'
