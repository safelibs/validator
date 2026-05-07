#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r12-ed-move-node
# @title: xmlstarlet ed -m relocates a matched node to a new parent path
# @description: Edits a small two-section document with xmlstarlet ed -m to move /root/a/item under /root/b, and asserts /root/a no longer contains an item child while /root/b gains the item with its original text intact.
# @timeout: 60
# @tags: usage, xmlstarlet, edit
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <a>
    <item>moved-text</item>
  </a>
  <b/>
</root>
XML

xmlstarlet ed -m '/root/a/item' '/root/b' "$tmpdir/in.xml" >"$tmpdir/out.xml"

# After the move, /root/b/item exists with the original text and /root/a is empty of item.
got_b=$(xmlstarlet sel -t -v 'string(/root/b/item)' "$tmpdir/out.xml")
[[ "$got_b" == "moved-text" ]] || {
    printf 'expected /root/b/item text "moved-text", got %q\n' "$got_b" >&2
    cat "$tmpdir/out.xml" >&2
    exit 1
}

remaining_a=$(xmlstarlet sel -t -v 'count(/root/a/item)' "$tmpdir/out.xml")
[[ "$remaining_a" == "0" ]] || {
    printf 'expected count(/root/a/item)=0 after move, got %q\n' "$remaining_a" >&2
    cat "$tmpdir/out.xml" >&2
    exit 1
}
