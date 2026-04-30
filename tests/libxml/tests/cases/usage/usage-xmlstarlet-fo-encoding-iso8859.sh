#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-fo-encoding-iso8859
# @title: xmlstarlet fo re-encode UTF-8 to ISO-8859-1
# @description: Pipes a UTF-8 XML document containing Latin-1-representable characters through xmlstarlet fo with -e ISO-8859-1, then verifies the produced declaration advertises ISO-8859-1, the bytes are no longer valid UTF-8 (proving an encoding conversion happened), and the original characters round-trip back to their UTF-8 form when decoded as ISO-8859-1.
# @timeout: 180
# @tags: usage, xml, cli, encoding
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Source document is UTF-8 with Latin-1-representable accents.
cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <item lang="fr">café</item>
  <item lang="de">grün</item>
  <item lang="es">señor</item>
</root>
XML

xmlstarlet fo -e ISO-8859-1 "$tmpdir/in.xml" >"$tmpdir/out.xml"

# Declaration advertises the new encoding.
validator_assert_contains "$tmpdir/out.xml" 'encoding="ISO-8859-1"'

# Element structure is preserved.
validator_assert_contains "$tmpdir/out.xml" '<item lang="fr">'
validator_assert_contains "$tmpdir/out.xml" '<item lang="de">'
validator_assert_contains "$tmpdir/out.xml" '<item lang="es">'

# After conversion, the file is no longer valid UTF-8 (single 0xE9 etc.),
# but is valid ISO-8859-1; round-trip via iconv must yield the originals.
if iconv -f UTF-8 -t UTF-8 "$tmpdir/out.xml" >/dev/null 2>&1; then
  printf 'expected output to NOT be valid UTF-8 after ISO-8859-1 conversion\n' >&2
  cat "$tmpdir/out.xml" >&2
  exit 1
fi

iconv -f ISO-8859-1 -t UTF-8 "$tmpdir/out.xml" >"$tmpdir/decoded.xml"
validator_assert_contains "$tmpdir/decoded.xml" 'café'
validator_assert_contains "$tmpdir/decoded.xml" 'grün'
validator_assert_contains "$tmpdir/decoded.xml" 'señor'
