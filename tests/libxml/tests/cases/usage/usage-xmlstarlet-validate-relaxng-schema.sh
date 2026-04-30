#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-validate-relaxng-schema
# @title: xmlstarlet val RelaxNG
# @description: Validates a conforming document and rejects a non-conforming document against a RelaxNG schema using xmlstarlet val -r and verifies the per-document validity verdicts.
# @timeout: 180
# @tags: usage, xml, cli, validation
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/schema.rng" <<'RNG'
<element name="catalog" xmlns="http://relaxng.org/ns/structure/1.0">
  <oneOrMore>
    <element name="item">
      <attribute name="id"><text/></attribute>
      <text/>
    </element>
  </oneOrMore>
</element>
RNG

cat >"$tmpdir/good.xml" <<'XML'
<catalog>
  <item id="1">alpha</item>
  <item id="2">beta</item>
</catalog>
XML

cat >"$tmpdir/bad.xml" <<'XML'
<catalog>
  <item id="1">alpha</item>
  <item>missing-id</item>
</catalog>
XML

# xmlstarlet's `val` subcommand on Ubuntu 24.04 does not accept --nonet;
# only --net (opt-in) is recognized. Default behaviour is already offline.
xmlstarlet val -r "$tmpdir/schema.rng" "$tmpdir/good.xml" >"$tmpdir/good.out"
set +e
xmlstarlet val -e -r "$tmpdir/schema.rng" "$tmpdir/bad.xml" >"$tmpdir/bad.out" 2>&1
bad_status=$?
set -e

validator_assert_contains "$tmpdir/good.out" 'good.xml - valid'
[[ "$bad_status" -ne 0 ]] || {
  printf 'expected non-zero exit on invalid doc, got %s\n' "$bad_status" >&2
  exit 1
}
validator_assert_contains "$tmpdir/bad.out" 'bad.xml'
