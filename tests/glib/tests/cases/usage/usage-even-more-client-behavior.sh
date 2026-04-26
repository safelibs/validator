#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

case "$case_id" in
  usage-gio-copy-overwrite-file)
    printf 'old\n' >"$tmpdir/out.txt"
    printf 'new payload\n' >"$tmpdir/in.txt"
    rm "$tmpdir/out.txt"
    gio copy "$tmpdir/in.txt" "$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'new payload'
    ;;
  usage-gio-move-renamed-file)
    printf 'move payload\n' >"$tmpdir/input.txt"
    gio move "$tmpdir/input.txt" "$tmpdir/renamed.txt"
    validator_assert_contains "$tmpdir/renamed.txt" 'move payload'
    test ! -e "$tmpdir/input.txt"
    ;;
  usage-gio-info-content-type)
    printf 'plain text payload\n' >"$tmpdir/input.txt"
    gio info -a standard::content-type "$tmpdir/input.txt" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'text/plain'
    ;;
  usage-gio-info-standard-name)
    printf 'name payload\n' >"$tmpdir/input.txt"
    gio info -a standard::name "$tmpdir/input.txt" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'input.txt'
    ;;
  usage-glib-compile-schemas-double)
    write_double_schema
    glib-compile-schemas "$tmpdir/schemas-double"
    GSETTINGS_SCHEMA_DIR="$tmpdir/schemas-double" gsettings get org.validator.double ratio | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2.5'
    ;;
  usage-glib-compile-schemas-int-array)
    write_int_array_schema
    glib-compile-schemas "$tmpdir/schemas-array"
    GSETTINGS_SCHEMA_DIR="$tmpdir/schemas-array" gsettings get org.validator.int-array items | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '1'
    validator_assert_contains "$tmpdir/out" '3'
    ;;
  usage-python3-gi-keyfile-roundtrip)
    python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
key = GLib.KeyFile()
key.set_string('demo', 'name', 'alpha')
key.set_integer('demo', 'count', 7)
print(key.to_data()[0])
PY
    validator_assert_contains "$tmpdir/out" 'name=alpha'
    validator_assert_contains "$tmpdir/out" 'count=7'
    ;;
  usage-python3-gi-bytes-size)
    python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
payload = GLib.Bytes.new(b'bytes payload')
print(payload.get_size())
PY
    grep -Fxq '13' "$tmpdir/out"
    ;;
  usage-python3-gi-file-load-contents)
    printf 'load contents payload\n' >"$tmpdir/input.txt"
    INPUT_PATH="$tmpdir/input.txt" python3 >"$tmpdir/out" <<'PY'
import os
from gi.repository import Gio
file = Gio.File.new_for_path(os.environ['INPUT_PATH'])
_, data, _ = file.load_contents(None)
print(data.decode())
PY
    validator_assert_contains "$tmpdir/out" 'load contents payload'
    ;;
  usage-python3-gi-memory-input-stream-read)
    python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib, Gio
stream = Gio.MemoryInputStream.new_from_bytes(GLib.Bytes.new(b'memory input payload'))
print(stream.read_bytes(64, None).get_data().decode())
PY
    validator_assert_contains "$tmpdir/out" 'memory input payload'
    ;;
  *)
    printf 'unknown glib even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
