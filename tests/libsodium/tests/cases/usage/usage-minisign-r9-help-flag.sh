#!/usr/bin/env bash
# @testcase: usage-minisign-r9-help-flag
# @title: minisign -h surfaces usage banner
# @description: Invokes minisign with -h and verifies the help output mentions the verify and sign subcommands.
# @timeout: 60
# @tags: usage, minisign, cli
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# minisign -h prints help to stderr and exits non-zero on some builds; capture both.
minisign -h >"$tmpdir/out.txt" 2>"$tmpdir/err.txt" || true

cat "$tmpdir/out.txt" "$tmpdir/err.txt" >"$tmpdir/all.txt"
validator_assert_contains "$tmpdir/all.txt" 'sign'
validator_assert_contains "$tmpdir/all.txt" 'verify'
