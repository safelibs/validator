#!/usr/bin/env bash
# @testcase: usage-bzip2-space-filename-compress
# @title: bzip2 space filename compress
# @description: Compresses a filename containing spaces with bzip2 and verifies the .bz2 output is created.
# @timeout: 180
# @tags: usage, bzip2, filesystem
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-space-filename-compress"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'space payload\n' >"$tmpdir/space name.txt"
bzip2 "$tmpdir/space name.txt"
validator_require_file "$tmpdir/space name.txt.bz2"
