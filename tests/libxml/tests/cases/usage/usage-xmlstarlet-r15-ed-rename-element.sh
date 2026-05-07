#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r15-ed-rename-element
# @title: xmlstarlet ed -r renames every matched element to the supplied tag while preserving children and attributes
# @description: Runs xmlstarlet ed -r against an XPath that matches multiple elements and asserts the rewritten output replaces the old tag with the new tag on every match while keeping each element's text and any attribute values intact.
# @timeout: 60
# @tags: usage, xmlstarlet, edit, rename
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root>
  <old kind="a">first</old>
  <old kind="b">second</old>
</root>
XML

xmlstarlet ed -r '//old' -v 'fresh' "$tmpdir/in.xml" >"$tmpdir/out"

# Old tag must be gone, new tag must be present twice with attributes/text.
if grep -F '<old' "$tmpdir/out" >/dev/null; then
    printf 'unexpected residual <old> in renamed output\n' >&2
    cat "$tmpdir/out" >&2
    exit 1
fi
validator_assert_contains "$tmpdir/out" '<fresh kind="a">first</fresh>'
validator_assert_contains "$tmpdir/out" '<fresh kind="b">second</fresh>'

# Two replacements expected.
count=$(grep -c '<fresh ' "$tmpdir/out" || true)
[[ "$count" == "2" ]] || {
    printf 'expected 2 <fresh> elements, got %s\n' "$count" >&2
    cat "$tmpdir/out" >&2
    exit 1
}
