#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r14-c14n-sorts-attributes
# @title: xmlstarlet c14n canonicalizes a document by alphabetizing each element's attributes
# @description: Runs xmlstarlet c14n on a document whose attributes appear in non-alphabetical order on multiple elements, captures stdout, and asserts the canonicalized output reorders each element's attributes alphabetically (a before b on the root, m before z on the child) and expands self-closing tags into open/close pairs.
# @timeout: 60
# @tags: usage, xmlstarlet, c14n
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<r b="2" a="1"><x z="9" m="3"/></r>
XML

xmlstarlet c14n "$tmpdir/in.xml" >"$tmpdir/out"

# Canonical form sorts attributes alphabetically.
validator_assert_contains "$tmpdir/out" '<r a="1" b="2">'
validator_assert_contains "$tmpdir/out" '<x m="3" z="9">'
# Self-closing tag is expanded under c14n.
validator_assert_contains "$tmpdir/out" '</x>'
# c14n omits the XML declaration.
if grep -q '<?xml' "$tmpdir/out"; then
    printf 'unexpected XML prolog in c14n output\n' >&2
    cat "$tmpdir/out" >&2
    exit 1
fi
