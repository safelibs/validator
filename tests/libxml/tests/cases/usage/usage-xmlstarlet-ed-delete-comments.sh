#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-ed-delete-comments
# @title: xmlstarlet ed delete all comment nodes
# @description: Runs xmlstarlet ed with a -d expression that selects every XML comment node anywhere in the document and verifies the result preserves all element content and attributes while removing every comment, including comments nested inside child elements.
# @timeout: 180
# @tags: usage, xml, cli, ed
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root>
  <!--top-comment-->
  <item id="a">alpha</item>
  <group>
    <!--inner-comment-->
    <item id="b">beta</item>
  </group>
  <!--trailing-comment-->
</root>
XML

xmlstarlet ed -d '//comment()' "$tmpdir/in.xml" >"$tmpdir/out.xml"

# Element content and attributes survive.
validator_assert_contains "$tmpdir/out.xml" '<item id="a">alpha</item>'
validator_assert_contains "$tmpdir/out.xml" '<item id="b">beta</item>'
validator_assert_contains "$tmpdir/out.xml" '<group>'

# All three comments are removed.
for needle in 'top-comment' 'inner-comment' 'trailing-comment'; do
  if grep -Fq "$needle" "$tmpdir/out.xml"; then
    printf 'comment %s still present after delete\n' "$needle" >&2
    cat "$tmpdir/out.xml" >&2
    exit 1
  fi
done

# Confirm with xmlstarlet itself: zero comment nodes remain.
remaining=$(xmlstarlet sel -t -v 'count(//comment())' "$tmpdir/out.xml")
[[ "$remaining" == "0" ]] || {
  printf 'expected 0 comments after delete, got %s\n' "$remaining" >&2
  exit 1
}

# But the two items still count as 2.
items=$(xmlstarlet sel -t -v 'count(//item)' "$tmpdir/out.xml")
[[ "$items" == "2" ]] || {
  printf 'expected 2 items after delete, got %s\n' "$items" >&2
  exit 1
}
