#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

case "$case_id" in
  usage-gio-copy-directory-tree)
    mkdir -p "$tmpdir/destdir"
    printf 'directory target payload\n' >"$tmpdir/input.txt"
    gio copy "$tmpdir/input.txt" "$tmpdir/destdir/"
    validator_assert_contains "$tmpdir/destdir/input.txt" 'directory target payload'
    ;;
  usage-gio-info-hidden-flag)
    printf 'hidden payload\n' >"$tmpdir/.hidden"
    gio info -a standard::is-hidden "$tmpdir/.hidden" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'TRUE'
    ;;
  usage-gio-info-symlink-target)
    printf 'target payload\n' >"$tmpdir/target.txt"
    ln -s "$tmpdir/target.txt" "$tmpdir/link.txt"
    gio info -a standard::symlink-target "$tmpdir/link.txt" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'target.txt'
    ;;
  usage-glib-compile-schemas-int)
    write_int_schema
    glib-compile-schemas "$tmpdir/schemas-int"
    GSETTINGS_SCHEMA_DIR="$tmpdir/schemas-int" gsettings get org.validator.more-int count | tee "$tmpdir/out"
    grep -Fxq '7' "$tmpdir/out"
    ;;
  usage-glib-compile-schemas-string-array)
    write_array_schema
    glib-compile-schemas "$tmpdir/schemas-array"
    GSETTINGS_SCHEMA_DIR="$tmpdir/schemas-array" gsettings get org.validator.more-array items | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" "'alpha'"
    validator_assert_contains "$tmpdir/out" "'beta'"
    ;;
  usage-python3-gi-keyfile-keys)
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
    ;;
  usage-python3-gi-checksum-md5)
    python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
checksum = GLib.Checksum.new(GLib.ChecksumType.MD5)
checksum.update(b"payload")
print(checksum.get_string())
PY
    validator_assert_contains "$tmpdir/out" '321c3cf486ed509164edec1e1981fec8'
    ;;
  usage-python3-gi-memory-output-stream)
    python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib, Gio
stream = Gio.MemoryOutputStream.new_resizable()
stream.write_bytes(GLib.Bytes.new(b"memory output"), None)
stream.close(None)
payload = stream.steal_as_bytes().get_data().decode()
print(payload)
PY
    validator_assert_contains "$tmpdir/out" 'memory output'
    ;;
  usage-python3-gi-uri-parse)
    python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
uri = GLib.Uri.parse("https://example.invalid/demo/path?name=alpha", GLib.UriFlags.NONE)
print(uri.get_scheme())
print(uri.get_host())
print(uri.get_path())
PY
    validator_assert_contains "$tmpdir/out" 'https'
    validator_assert_contains "$tmpdir/out" 'example.invalid'
    validator_assert_contains "$tmpdir/out" '/demo/path'
    ;;
  usage-python3-gi-file-query-exists)
    printf 'exists payload\n' >"$tmpdir/input.txt"
    INPUT_PATH="$tmpdir/input.txt" python3 >"$tmpdir/out" <<'PY'
import os
from gi.repository import Gio
file = Gio.File.new_for_path(os.environ["INPUT_PATH"])
print(file.query_exists(None))
PY
    validator_assert_contains "$tmpdir/out" 'True'
    ;;
  *)
    printf 'unknown glib additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
