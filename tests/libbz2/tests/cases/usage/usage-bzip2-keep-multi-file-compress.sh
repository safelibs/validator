#!/usr/bin/env bash
# @testcase: usage-bzip2-keep-multi-file-compress
# @title: bzip2 keep multi-file compress
# @description: Compresses two files with bzip2 -k and verifies the originals and compressed outputs both remain present.
# @timeout: 180
# @tags: usage, bzip2, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-keep-multi-file-compress"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\n' >"$tmpdir/alpha.txt"
printf 'beta\n' >"$tmpdir/beta.txt"
bzip2 -k "$tmpdir/alpha.txt" "$tmpdir/beta.txt"
validator_require_file "$tmpdir/alpha.txt"
validator_require_file "$tmpdir/beta.txt"
validator_require_file "$tmpdir/alpha.txt.bz2"
validator_require_file "$tmpdir/beta.txt.bz2"
