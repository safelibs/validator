#!/usr/bin/env bash
# @testcase: usage-bzip2-batch11-bzmore-pager-cat
# @title: bzmore pager cat
# @description: Reads a compressed file through bzmore with cat as the pager and verifies the decompressed text.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-batch11-bzmore-pager-cat"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'more payload\n' >"$tmpdir/plain.txt"
bzip2 -k "$tmpdir/plain.txt"
PAGER=cat bzmore "$tmpdir/plain.txt.bz2" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'more payload'
