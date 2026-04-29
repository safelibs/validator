#!/usr/bin/env bash
# @testcase: usage-bzip2-test-sample1
# @title: bzip2 tests sample1 fixture
# @description: Runs bzip2 test mode against the bundled sample1 fixture and verifies stream integrity.
# @timeout: 180
# @tags: usage, compression, fixture
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-test-sample1"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample=${case_id#usage-bzip2-test-}
validator_require_file "$VALIDATOR_SAMPLE_ROOT/${sample}.bz2"
bzip2 -t "$VALIDATOR_SAMPLE_ROOT/${sample}.bz2"
printf '%s ok\n' "$sample"
