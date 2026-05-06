#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r11-ed-in-place-deletes
# @title: xmlstarlet ed -L deletes a matched node directly in the source file
# @description: Writes a small two-element XML document, runs xmlstarlet ed -L to delete one element by xpath against the file in place, and asserts the on-disk file lost the matched element while keeping the sibling.
# @timeout: 60
# @tags: usage, xmlstarlet, edit
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <a>delete-me</a>
  <b>keep-me</b>
</root>
XML

xmlstarlet ed -L -d '/root/a' "$tmpdir/in.xml"

grep -q '<b>keep-me</b>' "$tmpdir/in.xml"
if grep -q 'delete-me' "$tmpdir/in.xml"; then
    echo "deleted node still present" >&2
    cat "$tmpdir/in.xml" >&2
    exit 1
fi
