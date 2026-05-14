#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r17-val-exit-code-valid-vs-invalid
# @title: xmlstarlet val exits 0 on well-formed input and non-zero on malformed input
# @description: Runs xmlstarlet val on a well-formed XML document (expects exit 0) and on a malformed one with an unclosed tag (expects non-zero exit), exercising the well-formedness validator's exit-code contract.
# @timeout: 60
# @tags: usage, xmlstarlet, val
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/good.xml" <<'XML'
<?xml version="1.0"?>
<root><child>ok</child></root>
XML

cat >"$tmpdir/bad.xml" <<'XML'
<?xml version="1.0"?>
<root><child>nope</root>
XML

xmlstarlet val "$tmpdir/good.xml" >/dev/null

if xmlstarlet val "$tmpdir/bad.xml" >/dev/null 2>&1; then
    echo "expected xmlstarlet val to fail on malformed input" >&2
    exit 1
fi
