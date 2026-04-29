#!/usr/bin/env bash
# @testcase: usage-python3-gi-checksum-sha256-string
# @title: PyGObject GLib SHA256 checksum
# @description: Computes a SHA256 digest of a string through GLib compute_checksum_for_string and verifies the hex digest from PyGObject.
# @timeout: 180
# @tags: usage, python, checksum
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-checksum-sha256-string"
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
print(GLib.compute_checksum_for_string(GLib.ChecksumType.SHA256, 'validator', -1))
PYCASE
validator_assert_contains "$tmpdir/out" 'f82af32160bc53112ca118abbf57fa6fed47eb90291a1d1d92f438ae2ed74ef6'
