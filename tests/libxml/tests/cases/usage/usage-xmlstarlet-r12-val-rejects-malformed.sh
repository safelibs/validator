#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r12-val-rejects-malformed
# @title: xmlstarlet val -e rejects a malformed XML document with a non-zero exit code
# @description: Pipes a malformed XML document through xmlstarlet val -e, asserts the command exits non-zero, and verifies a well-formed document still validates with exit 0 to confirm the validator is not failing unconditionally.
# @timeout: 60
# @tags: usage, xmlstarlet, validate
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Missing closing tag -> malformed.
cat >"$tmpdir/bad.xml" <<'XML'
<root>
  <child>oops
</root>
XML

cat >"$tmpdir/good.xml" <<'XML'
<root>
  <child>ok</child>
</root>
XML

set +e
xmlstarlet val -e "$tmpdir/bad.xml" >"$tmpdir/bad.out" 2>&1
ec_bad=$?
set -e
[[ $ec_bad -ne 0 ]] || {
    printf 'expected xmlstarlet val to fail on malformed input\n' >&2
    cat "$tmpdir/bad.out" >&2
    exit 1
}

xmlstarlet val -e "$tmpdir/good.xml" >"$tmpdir/good.out" 2>&1
