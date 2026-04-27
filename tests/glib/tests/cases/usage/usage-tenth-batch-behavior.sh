#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

case "$case_id" in
  usage-glib-compile-schemas-string-array-list)
    write_string_array_schema
    glib-compile-schemas "$tmpdir/schemas-strarr"
    GSETTINGS_SCHEMA_DIR="$tmpdir/schemas-strarr" gsettings get org.validator.strarr words >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha'
    validator_assert_contains "$tmpdir/out" 'gamma'
    ;;
  usage-glib-compile-schemas-uint-default)
    write_enum_schema
    glib-compile-schemas "$tmpdir/schemas-uint"
    GSETTINGS_SCHEMA_DIR="$tmpdir/schemas-uint" gsettings get org.validator.uint threshold >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '42'
    ;;
  usage-gio-cat-multiple-files)
    printf 'first half\n' >"$tmpdir/a.txt"
    printf 'second half\n' >"$tmpdir/b.txt"
    gio cat "$tmpdir/a.txt" "$tmpdir/b.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'first half'
    validator_assert_contains "$tmpdir/out" 'second half'
    ;;
  usage-gio-info-unix-mode-attribute)
    printf 'mode payload\n' >"$tmpdir/file.txt"
    chmod 0644 "$tmpdir/file.txt"
    gio info -a unix::mode "$tmpdir/file.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'unix::mode:'
    ;;
  usage-python3-gi-string-replace)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(GLib.uri_escape_string('alpha beta', None, False))
PYCASE
    validator_assert_contains "$tmpdir/out" 'alpha%20beta'
    ;;
  usage-python3-gi-checksum-sha256-string)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
print(GLib.compute_checksum_for_string(GLib.ChecksumType.SHA256, 'validator', -1))
PYCASE
    validator_assert_contains "$tmpdir/out" 'f82af32160bc53112ca118abbf57fa6fed47eb90291a1d1d92f438ae2ed74ef6'
    ;;
  usage-python3-gi-base64-decode)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
data = GLib.base64_decode('dmFsaWRhdG9y')
print(bytes(data).decode())
PYCASE
    validator_assert_contains "$tmpdir/out" 'validator'
    ;;
  usage-python3-gi-keyfile-double)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
key = GLib.KeyFile()
key.set_double('demo', 'ratio', 1.5)
print(key.get_double('demo', 'ratio'))
PYCASE
    validator_assert_contains "$tmpdir/out" '1.5'
    ;;
  usage-python3-gi-variant-array-strings)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
value = GLib.Variant('as', ['alpha', 'beta', 'gamma'])
print(value.n_children())
print(value.get_child_value(1).get_string())
PYCASE
    validator_assert_contains "$tmpdir/out" '3'
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-python3-gi-datetime-iso-string)
    python3 >"$tmpdir/out" <<'PYCASE'
from gi.repository import GLib
dt = GLib.DateTime.new_utc(2024, 6, 1, 12, 30, 45)
print(dt.format_iso8601())
PYCASE
    validator_assert_contains "$tmpdir/out" '2024-06-01T12:30:45Z'
    ;;
  *)
    printf 'unknown glib tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
