#!/usr/bin/env bash
# @testcase: usage-bunzip2-test-alias
# @title: bunzip2 test alias
# @description: Runs bunzip2 -t against a valid .bz2 stream and verifies the integrity check succeeds.
# @timeout: 180
# @tags: usage, bzip2, integrity
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bunzip2-test-alias"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alias payload\n' >"$tmpdir/input.txt"
bzip2 "$tmpdir/input.txt"
bunzip2 -t "$tmpdir/input.txt.bz2"
