#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r14-val-well-formed-only
# @title: xmlstarlet val --well-formed accepts well-formed XML and rejects malformed XML
# @description: Runs xmlstarlet val --well-formed against a well-formed document and asserts a "valid" verdict and exit 0. Repeats with a malformed document where the close tag is mismatched and asserts a non-zero exit code, demonstrating the well-formedness gate.
# @timeout: 60
# @tags: usage, xmlstarlet, validation
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/good.xml" <<'XML'
<?xml version="1.0"?>
<root><a>1</a><b>2</b></root>
XML
cat >"$tmpdir/bad.xml" <<'XML'
<?xml version="1.0"?>
<root><a>1</b></root>
XML

xmlstarlet val --well-formed "$tmpdir/good.xml" >"$tmpdir/good.out" 2>"$tmpdir/good.err"
validator_assert_contains "$tmpdir/good.out" 'valid'

set +e
xmlstarlet val --well-formed "$tmpdir/bad.xml" >"$tmpdir/bad.out" 2>"$tmpdir/bad.err"
ec=$?
set -e
[[ "$ec" -ne 0 ]] || {
    printf 'expected non-zero exit on malformed XML, got 0\n' >&2
    cat "$tmpdir/bad.out" "$tmpdir/bad.err" >&2
    exit 1
}
# Output should not call the malformed file "valid".
if grep -E '^[^[:space:]]*bad\.xml - valid' "$tmpdir/bad.out" >/dev/null 2>&1; then
    printf 'unexpected "valid" verdict on malformed XML\n' >&2
    cat "$tmpdir/bad.out" >&2
    exit 1
fi
