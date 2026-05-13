#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r16-fo-indent-spaces-four
# @title: xmlstarlet fo --indent-spaces 4 formats nested children with four-space indentation
# @description: Runs xmlstarlet fo --indent-spaces 4 on a compact document with nested elements and asserts the reformatted output indents the <child> line with exactly four leading spaces (and the <grandchild> with exactly eight), confirming the indent-spaces setting takes effect.
# @timeout: 60
# @tags: usage, xmlstarlet, format, indent
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root><child><grandchild>v</grandchild></child></root>
XML

xmlstarlet fo --indent-spaces 4 "$tmpdir/in.xml" >"$tmpdir/out"

# 4-space leading indent on <child>, 8-space on <grandchild>.
grep -nE '^    <child>' "$tmpdir/out" >/dev/null || {
    printf 'expected 4-space indent on <child>\n' >&2
    cat -A "$tmpdir/out" >&2
    exit 1
}
grep -nE '^        <grandchild>' "$tmpdir/out" >/dev/null || {
    printf 'expected 8-space indent on <grandchild>\n' >&2
    cat -A "$tmpdir/out" >&2
    exit 1
}
