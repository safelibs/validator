#!/usr/bin/env bash
# @testcase: usage-gzip-stdout-roundtrip
# @title: gzip stdout round trip
# @description: Compresses to stdout with gzip, decompresses from stdout, and verifies the original payload returns intact.
# @timeout: 180
# @tags: usage, archive
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gzip-stdout-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'stdout payload\n' >"$tmpdir/in.txt"
gzip -c "$tmpdir/in.txt" >"$tmpdir/in.txt.gz"
gzip -dc "$tmpdir/in.txt.gz" >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'stdout payload'
