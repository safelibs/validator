#!/usr/bin/env bash
# @testcase: usage-python3-gi-file-enumerator
# @title: PyGObject file enumerator
# @description: Enumerates local files with Gio.File enumerator APIs from PyGObject.
# @timeout: 180
# @tags: usage, gio, python
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-file-enumerator"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_bool_schema() {
  mkdir -p "$tmpdir/schemas"
  cat >"$tmpdir/schemas/org.validator.extra.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.extra" path="/org/validator/extra/">
    <key name="enabled" type="b">
      <default>true</default>
    </key>
  </schema>
</schemalist>
XML
}

write_string_schema() {
  mkdir -p "$tmpdir/schemas-string"
  cat >"$tmpdir/schemas-string/org.validator.extra-string.gschema.xml" <<'XML'
<schemalist>
  <schema id="org.validator.extra-string" path="/org/validator/extra-string/">
    <key name="label" type="s">
      <default>'alpha'</default>
    </key>
  </schema>
</schemalist>
XML
}

printf 'alpha\n' >"$tmpdir/alpha.txt"
printf 'beta\n' >"$tmpdir/beta.txt"
python3 - "$tmpdir" >"$tmpdir/out" <<'PY'
from gi.repository import Gio
import sys
directory = Gio.File.new_for_path(sys.argv[1])
enumerator = directory.enumerate_children("standard::name", Gio.FileQueryInfoFlags.NONE, None)
names = []
while True:
    info = enumerator.next_file(None)
    if info is None:
        break
    names.append(info.get_name())
enumerator.close(None)
print(",".join(sorted(names)))
PY
validator_assert_contains "$tmpdir/out" 'alpha.txt'
validator_assert_contains "$tmpdir/out" 'beta.txt'
