#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r12-sel-substring-after-fn
# @title: xmlstarlet sel substring-after() returns the suffix after a separator
# @description: Runs xmlstarlet sel -t -v with the XPath function substring-after(@name, '-') against an attribute that carries a hyphenated value, and asserts the emitted output is exactly the suffix portion of the attribute string.
# @timeout: 60
# @tags: usage, xmlstarlet, xpath
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<r>
  <item name="alpha-beta-gamma"/>
</r>
XML

xmlstarlet sel -t -v 'substring-after(/r/item/@name, "-")' "$tmpdir/in.xml" >"$tmpdir/out"
got=$(cat "$tmpdir/out")
[[ "$got" == "beta-gamma" ]] || {
    printf 'expected "beta-gamma", got %q\n' "$got" >&2
    exit 1
}
