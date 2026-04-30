#!/usr/bin/env bash
# @testcase: usage-coreutils-numfmt-iec
# @title: coreutils numfmt iec scaling
# @description: Converts byte counts to and from IEC units with numfmt and verifies both directions.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-numfmt-iec"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

numfmt --to=iec 1048576 >"$tmpdir/to.out"
numfmt --from=iec 2K >"$tmpdir/from.out"

validator_assert_contains "$tmpdir/to.out" '1.0M'
validator_assert_contains "$tmpdir/from.out" '2048'
