#!/usr/bin/env bash
# @testcase: usage-bzip2-stdin-stdout-roundtrip
# @title: bzip2 stdin stdout round trip
# @description: Compresses data from stdin with bzip2, decompresses to stdout, and verifies the original payload returns intact.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-stdin-stdout-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'stdin roundtrip payload\n' | bzip2 -c >"$tmpdir/in.bz2"
bzip2 -dc "$tmpdir/in.bz2" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'stdin roundtrip payload'
