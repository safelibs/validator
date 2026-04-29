#!/usr/bin/env bash
# @testcase: usage-bzip2-sample3-stdout
# @title: bzip2 sample three stdout
# @description: Exercises bzip2 sample three stdout through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-sample3-stdout"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample_root="$VALIDATOR_SAMPLE_ROOT"

bzip2 -dc "$sample_root/sample3.bz2" >"$tmpdir/out.txt"
cmp "$sample_root/sample3.ref" "$tmpdir/out.txt"
