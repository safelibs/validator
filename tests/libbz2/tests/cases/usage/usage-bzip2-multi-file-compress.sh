#!/usr/bin/env bash
# @testcase: usage-bzip2-multi-file-compress
# @title: bzip2 multi-file compress
# @description: Compresses two files with bzip2 in one invocation and verifies both .bz2 outputs are created.
# @timeout: 180
# @tags: usage, bzip2, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-multi-file-compress"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\n' >"$tmpdir/alpha.txt"
printf 'beta\n' >"$tmpdir/beta.txt"
bzip2 "$tmpdir/alpha.txt" "$tmpdir/beta.txt"
validator_require_file "$tmpdir/alpha.txt.bz2"
validator_require_file "$tmpdir/beta.txt.bz2"
