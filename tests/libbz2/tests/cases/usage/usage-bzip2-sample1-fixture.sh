#!/usr/bin/env bash
# @testcase: usage-bzip2-sample1-fixture
# @title: bzip2 sample1 fixture
# @description: Decompresses the sample1 fixture with bzip2 and compares the reference payload.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-sample1-fixture"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample=${case_id#usage-bzip2-}
sample=${sample%-fixture}
validator_require_file "$VALIDATOR_SAMPLE_ROOT/${sample}.bz2"
validator_require_file "$VALIDATOR_SAMPLE_ROOT/${sample}.ref"
bzip2 -dc "$VALIDATOR_SAMPLE_ROOT/${sample}.bz2" >"$tmpdir/out"
cmp "$VALIDATOR_SAMPLE_ROOT/${sample}.ref" "$tmpdir/out"
