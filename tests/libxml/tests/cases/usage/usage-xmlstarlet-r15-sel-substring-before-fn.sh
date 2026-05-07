#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r15-sel-substring-before-fn
# @title: xmlstarlet sel evaluates the XPath substring-before() function on a literal string argument
# @description: Runs xmlstarlet sel -t -v "substring-before('alpha-beta', '-')" against any well-formed input document and asserts the captured stdout is the literal "alpha", pinning the XPath 1.0 substring-before() semantics through xmlstarlet's selection harness.
# @timeout: 60
# @tags: usage, xmlstarlet, sel, xpath, substring-before
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root><n>1</n></root>
XML

xmlstarlet sel -t -v "substring-before('alpha-beta', '-')" -n "$tmpdir/in.xml" >"$tmpdir/out"

[[ "$(cat "$tmpdir/out")" == "alpha" ]] || {
    printf 'expected "alpha", got: %s\n' "$(cat "$tmpdir/out")" >&2
    exit 1
}
