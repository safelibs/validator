#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r19-val-well-formed-rejects-unclosed-tag
# @title: xmlstarlet val -w exits non-zero on an XML document with an unclosed tag
# @description: Writes an intentionally malformed XML document with an unclosed <a> tag, then runs xmlstarlet val -w which performs a well-formedness check only, and asserts the validator exits with a non-zero status while a separate well-formed sibling document exits zero.
# @timeout: 60
# @tags: usage, xmlstarlet, val, well-formed, r19
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/good.xml" <<'XML'
<?xml version="1.0"?>
<root><a/></root>
XML

cat >"$tmpdir/bad.xml" <<'XML'
<?xml version="1.0"?>
<root><a></root>
XML

xmlstarlet val -w "$tmpdir/good.xml" >"$tmpdir/good.log" 2>&1
status=0
xmlstarlet val -w "$tmpdir/bad.xml" >"$tmpdir/bad.log" 2>&1 || status=$?
[[ "$status" -ne 0 ]] || {
    echo "expected xmlstarlet val -w to fail on malformed document" >&2
    cat "$tmpdir/bad.log" >&2
    exit 1
}
