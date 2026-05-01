#!/usr/bin/env bash
# @testcase: usage-bzip2-test-quiet-suppresses-banner
# @title: bzip2 -tq quiet test mode
# @description: Runs bzip2 -tq on a known-good archive and verifies the integrity check passes silently with no output on stdout or stderr.
# @timeout: 60
# @tags: usage, bzip2, quiet
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-test-quiet-suppresses-banner"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'quiet integrity probe payload\n' >"$tmpdir/data.txt"
bzip2 -k "$tmpdir/data.txt"
validator_require_file "$tmpdir/data.txt.bz2"

bzip2 -tq "$tmpdir/data.txt.bz2" >"$tmpdir/out" 2>"$tmpdir/err"
[[ ! -s "$tmpdir/out" ]] || { printf 'expected empty stdout\n' >&2; cat "$tmpdir/out" >&2; exit 1; }
[[ ! -s "$tmpdir/err" ]] || { printf 'expected empty stderr\n' >&2; cat "$tmpdir/err" >&2; exit 1; }
