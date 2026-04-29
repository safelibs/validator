#!/usr/bin/env bash
# @testcase: usage-python3-gi-gio-file
# @title: PyGObject Gio file read
# @description: Loads file content through Gio APIs exposed by PyGObject.
# @timeout: 120
# @tags: usage, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-gio-file"
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

printf 'pygio payload\n' >"$tmpdir/input.txt"
INPUT_PATH="$tmpdir/input.txt" python3 >"$tmpdir/out" <<'PY'
import os
from gi.repository import Gio
file = Gio.File.new_for_path(os.environ["INPUT_PATH"])
ok, contents, etag = file.load_contents(None)
print(contents.decode("utf-8").strip())
PY
validator_assert_contains "$tmpdir/out" 'pygio payload'
