#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-edit-insert-pi-r7
# @title: xmlstarlet ed insert processing instruction
# @description: Uses xmlstarlet ed to insert a processing instruction node before the document root via -i with -t pi and verifies the rewritten output contains the new PI in the correct position and the original root content is preserved verbatim.
# @timeout: 120
# @tags: usage, xml, cli, xmlstarlet
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<root><item id="a">alpha</item></root>
XML

xmlstarlet ed \
  -i '/root' -t pi -n 'xml-stylesheet' -v 'type="text/xsl" href="style.xsl"' \
  "$tmpdir/in.xml" >"$tmpdir/out.xml"

validator_assert_contains "$tmpdir/out.xml" '<?xml-stylesheet type="text/xsl" href="style.xsl"?>'
validator_assert_contains "$tmpdir/out.xml" '<item id="a">alpha</item>'

# The PI should appear before <root> on its own line.
grep -n 'xml-stylesheet' "$tmpdir/out.xml" >"$tmpdir/pi-line"
grep -n '<root>' "$tmpdir/out.xml" >"$tmpdir/root-line"
pi_lineno=$(cut -d: -f1 "$tmpdir/pi-line" | head -n1)
root_lineno=$(cut -d: -f1 "$tmpdir/root-line" | head -n1)
[[ "$pi_lineno" -lt "$root_lineno" ]] || {
  printf 'expected PI line %s to precede <root> line %s\n' "$pi_lineno" "$root_lineno" >&2
  cat "$tmpdir/out.xml" >&2
  exit 1
}
