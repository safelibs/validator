#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r18-c14n-canonicalization-stable-order
# @title: xmlstarlet c14n canonicalization sorts attributes into deterministic order
# @description: Feeds an XML element with attributes declared in non-canonical order to xmlstarlet c14n, then verifies the canonicalized output places attribute 'a' before attribute 'b' as required by Canonical XML 1.0.
# @timeout: 60
# @tags: usage, xmlstarlet, c14n, r18
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root b="2" a="1"/>
XML

xmlstarlet c14n "$tmpdir/in.xml" >"$tmpdir/out.xml"
# Canonical form sorts attribute names lexicographically: a then b.
grep -Eq '<root a="1" b="2"' "$tmpdir/out.xml" || {
    printf 'expected attribute order a before b in canonical output\n' >&2
    cat "$tmpdir/out.xml" >&2
    exit 1
}
