#!/usr/bin/env bash
# @testcase: usage-curl-manual-display
# @title: curl --manual prints the embedded manual
# @description: Runs curl --manual and verifies the embedded manual text is emitted to stdout, including a recognizable curl(1) section heading and a zero exit status.
# @timeout: 60
# @tags: usage, curl, introspection
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-curl-manual-display"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

curl --manual >"$tmpdir/manual.txt"
test -s "$tmpdir/manual.txt"
validator_assert_contains "$tmpdir/manual.txt" 'curl - transfer a URL'
validator_assert_contains "$tmpdir/manual.txt" 'SYNOPSIS'
